import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotification {
  final String? id;
  final String? title;
  final String? body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? category;
  final String? badge;
  final String? sound;

  const FirebaseNotification({
    this.id,
    this.title,
    this.body,
    this.imageUrl,
    this.data = const {},
    required this.timestamp,
    this.category,
    this.badge,
    this.sound,
  });

  // Tạo từ RemoteMessage
  factory FirebaseNotification.fromRemoteMessage(RemoteMessage message) {
    return FirebaseNotification(
      id: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      imageUrl: message.notification?.android?.imageUrl ?? 
                message.notification?.apple?.imageUrl,
      data: message.data,
      timestamp: message.sentTime ?? DateTime.now(),
      category: message.category,
      badge: message.notification?.apple?.badge,
      sound: message.notification?.android?.sound ?? 
             message.notification?.apple?.sound?.name,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category,
      'badge': badge,
      'sound': sound,
    };
  }

  // Create from Map
  factory FirebaseNotification.fromMap(Map<String, dynamic> map) {
    return FirebaseNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      imageUrl: map['imageUrl'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      category: map['category'],
      badge: map['badge']?.toString(),
      sound: map['sound'],
    );
  }

  // Copy with method
  FirebaseNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? category,
    String? badge,
    String? sound,
  }) {
    return FirebaseNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      badge: badge ?? this.badge,
      sound: sound ?? this.sound,
    );
  }

  @override
  String toString() {
    return 'FirebaseNotification(id: $id, title: $title, body: $body, data: $data, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is FirebaseNotification &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.imageUrl == imageUrl &&
      other.data.toString() == data.toString() &&
      other.timestamp == timestamp &&
      other.category == category &&
      other.badge == badge &&
      other.sound == sound;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      imageUrl.hashCode ^
      data.hashCode ^
      timestamp.hashCode ^
      category.hashCode ^
      badge.hashCode ^
      sound.hashCode;
  }
} 