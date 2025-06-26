import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_filter.dart';
import '../../data/repositories/local_notification_repository.dart';
import '../../../../shared/services/firebase_service.dart';

// =============== EVENTS ===============

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

class NotificationRefreshRequested extends NotificationEvent {
  const NotificationRefreshRequested();
}

class NotificationFilterChanged extends NotificationEvent {
  final NotificationFilter filter;
  
  const NotificationFilterChanged(this.filter);
  
  @override
  List<Object?> get props => [filter];
}

class NotificationSearchChanged extends NotificationEvent {
  final String query;
  
  const NotificationSearchChanged(this.query);
  
  @override
  List<Object?> get props => [query];
}

class NotificationMarkAsRead extends NotificationEvent {
  final String notificationId;
  
  const NotificationMarkAsRead(this.notificationId);
  
  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllAsRead extends NotificationEvent {
  const NotificationMarkAllAsRead();
}

class NotificationDelete extends NotificationEvent {
  final String notificationId;
  
  const NotificationDelete(this.notificationId);
  
  @override
  List<Object?> get props => [notificationId];
}

class NotificationBulkDelete extends NotificationEvent {
  final List<String> notificationIds;
  
  const NotificationBulkDelete(this.notificationIds);
  
  @override
  List<Object?> get props => [notificationIds];
}

class NotificationReceived extends NotificationEvent {
  final NotificationItem notification;
  
  const NotificationReceived(this.notification);
  
  @override
  List<Object?> get props => [notification];
}

// =============== STATES ===============

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationItem> notifications;
  final List<NotificationItem> filteredNotifications;
  final NotificationFilter currentFilter;
  final String searchQuery;
  final int unreadCount;
  final bool isRefreshing;

  const NotificationLoaded({
    required this.notifications,
    required this.filteredNotifications,
    required this.currentFilter,
    required this.searchQuery,
    required this.unreadCount,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    notifications,
    filteredNotifications,
    currentFilter,
    searchQuery,
    unreadCount,
    isRefreshing,
  ];

  NotificationLoaded copyWith({
    List<NotificationItem>? notifications,
    List<NotificationItem>? filteredNotifications,
    NotificationFilter? currentFilter,
    String? searchQuery,
    int? unreadCount,
    bool? isRefreshing,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      filteredNotifications: filteredNotifications ?? this.filteredNotifications,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      unreadCount: unreadCount ?? this.unreadCount,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;
  final String? code;
  
  const NotificationError(this.message, {this.code});
  
  @override
  List<Object?> get props => [message, code];
}

class NotificationActionSuccess extends NotificationState {
  final String message;
  final NotificationActionType actionType;
  
  const NotificationActionSuccess(this.message, this.actionType);
  
  @override
  List<Object?> get props => [message, actionType];
}

enum NotificationActionType {
  markRead,
  markAllRead,
  delete,
  bulkDelete,
}

// =============== BLOC ===============

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final LocalNotificationRepository _repository;
  final FirebaseService _firebaseService;
  
  late StreamSubscription<NotificationItem> _notificationSubscription;
  late StreamSubscription<int> _unreadCountSubscription;
  
  NotificationBloc({
    required LocalNotificationRepository repository,
    required FirebaseService firebaseService,
  })  : _repository = repository,
        _firebaseService = firebaseService,
        super(const NotificationInitial()) {
    
    // Register event handlers
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationRefreshRequested>(_onRefreshRequested);
    on<NotificationFilterChanged>(_onFilterChanged);
    on<NotificationSearchChanged>(_onSearchChanged);
    on<NotificationMarkAsRead>(_onMarkAsRead);
    on<NotificationMarkAllAsRead>(_onMarkAllAsRead);
    on<NotificationDelete>(_onDelete);
    on<NotificationBulkDelete>(_onBulkDelete);
    on<NotificationReceived>(_onNotificationReceived);
    
    // Listen to real-time notification updates
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Listen to new notifications from Firebase
    _notificationSubscription = _firebaseService.onMessageReceived.listen(
      (notification) {
        add(NotificationReceived(notification));
      },
      onError: (error) {
        // Log error instead of adding to event stream
        if (kDebugMode) {
          print('Error receiving real-time notification: $error');
        }
      },
    );
  }

  @override
  Future<void> close() {
    _notificationSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    
    try {
      final notifications = await _repository.getFilteredNotifications();
      final unreadCount = await _repository.getUnreadCount();
      
      final loadedState = NotificationLoaded(
        notifications: notifications,
        filteredNotifications: notifications,
        currentFilter: const NotificationFilter(),
        searchQuery: '',
        unreadCount: unreadCount,
      );
      
      emit(loadedState);
    } catch (error) {
      emit(NotificationError('Lỗi tải thông báo: $error'));
    }
  }

  Future<void> _onRefreshRequested(
    NotificationRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
      
      try {
        final notifications = await _repository.getFilteredNotifications();
        final unreadCount = await _repository.getUnreadCount();
        
        final filtered = _applyFiltersAndSearch(
          notifications,
          currentState.currentFilter,
          currentState.searchQuery,
        );
        
        emit(currentState.copyWith(
          notifications: notifications,
          filteredNotifications: filtered,
          unreadCount: unreadCount,
          isRefreshing: false,
        ));
      } catch (error) {
        emit(currentState.copyWith(isRefreshing: false));
        emit(NotificationError('Lỗi refresh thông báo: $error'));
      }
    }
  }

  Future<void> _onFilterChanged(
    NotificationFilterChanged event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final filtered = _applyFiltersAndSearch(
        currentState.notifications,
        event.filter,
        currentState.searchQuery,
      );
      
      emit(currentState.copyWith(
        currentFilter: event.filter,
        filteredNotifications: filtered,
      ));
    }
  }

  Future<void> _onSearchChanged(
    NotificationSearchChanged event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final filtered = _applyFiltersAndSearch(
        currentState.notifications,
        currentState.currentFilter,
        event.query,
      );
      
      emit(currentState.copyWith(
        searchQuery: event.query,
        filteredNotifications: filtered,
      ));
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.updateNotificationStatus(
        event.notificationId,
        NotificationStatus.read,
      );
      
      // Refresh data
      add(const NotificationRefreshRequested());
      
      emit(const NotificationActionSuccess(
        'Đã đánh dấu thông báo là đã đọc',
        NotificationActionType.markRead,
      ));
    } catch (error) {
      emit(NotificationError('Lỗi đánh dấu đã đọc: $error'));
    }
  }

  Future<void> _onMarkAllAsRead(
    NotificationMarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead();
      
      // Refresh data
      add(const NotificationRefreshRequested());
      
      emit(const NotificationActionSuccess(
        'Đã đánh dấu tất cả thông báo là đã đọc',
        NotificationActionType.markAllRead,
      ));
    } catch (error) {
      emit(NotificationError('Lỗi đánh dấu tất cả đã đọc: $error'));
    }
  }

  Future<void> _onDelete(
    NotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.notificationId);
      
      // Refresh data
      add(const NotificationRefreshRequested());
      
      emit(const NotificationActionSuccess(
        'Đã xóa thông báo',
        NotificationActionType.delete,
      ));
    } catch (error) {
      emit(NotificationError('Lỗi xóa thông báo: $error'));
    }
  }

  Future<void> _onBulkDelete(
    NotificationBulkDelete event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      for (final id in event.notificationIds) {
        await _repository.deleteNotification(id);
      }
      
      // Refresh data
      add(const NotificationRefreshRequested());
      
      emit(NotificationActionSuccess(
        'Đã xóa ${event.notificationIds.length} thông báo',
        NotificationActionType.bulkDelete,
      ));
    } catch (error) {
      emit(NotificationError('Lỗi xóa nhiều thông báo: $error'));
    }
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      try {
        // Insert new notification into database
        await _repository.insertNotification(event.notification);
        
        // Refresh data to get latest notifications
        add(const NotificationRefreshRequested());
      } catch (error) {
        emit(NotificationError('Lỗi xử lý thông báo mới: $error'));
      }
    }
  }

  List<NotificationItem> _applyFiltersAndSearch(
    List<NotificationItem> notifications,
    NotificationFilter filter,
    String searchQuery,
  ) {
    var filtered = notifications.where(filter.matches).toList();
    
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((notification) =>
        notification.title.toLowerCase().contains(query) ||
        notification.message.toLowerCase().contains(query) ||
        (notification.senderName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }
} 