# Notification System Implementation Plan

## 📋 Tổng quan

### Mục tiêu
Implement hệ thống thông báo hoàn chỉnh cho PersonaAI với kiến trúc **Push Notification + Local Database** đơn giản, tập trung vào reliability và user experience.

### Scope
- ✅ Firebase Cloud Messaging (FCM) integration
- ✅ Local SQLite database cho persistence
- ✅ Enhanced notification filtering
- ✅ Real-time UI updates
- ✅ Background sync đơn giản
- ❌ Complex two-way sync (không cần)
- ❌ Advanced search (over-engineering)

---

## 🏗️ Kiến trúc Hệ thống

### Overall Architecture
```
Server → Firebase FCM → App (Foreground/Background)
                    ↓
            Local SQLite Database
                    ↓
           UI (NotificationPage)
```

### Data Flow
1. **Server gửi push notification** qua FCM
2. **App nhận notification** (foreground/background)
3. **Lưu vào local SQLite** ngay lập tức
4. **Update UI** real-time nếu app đang mở
5. **App startup**: Fetch missed notifications từ server API
6. **User interactions**: Mark read/delete → Update local → Optional API call

---

## 🗄️ Database Design

### SQLite Schema
```sql
-- Main notifications table
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,                    -- Server notification ID
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,                     -- 'attendance', 'training', etc.
  status TEXT NOT NULL DEFAULT 'unread', -- 'unread', 'read', 'archived'
  priority TEXT NOT NULL DEFAULT 'normal', -- 'low', 'normal', 'high', 'urgent'
  created_at INTEGER NOT NULL,           -- Unix timestamp (milliseconds)
  read_at INTEGER NULL,                  -- When user marked as read
  scheduled_at INTEGER NULL,             -- For scheduled notifications
  action_url TEXT NULL,                  -- Deep link URL
  metadata TEXT NULL,                    -- JSON string for extra data
  image_url TEXT NULL,                   -- Notification image
  sender_id TEXT NULL,                   -- Sender ID from server
  sender_name TEXT NULL,                 -- Display name
  is_actionable INTEGER DEFAULT 0,       -- Requires user action (0/1)
  
  -- Local tracking
  received_at INTEGER NOT NULL,          -- When app received FCM
  source TEXT DEFAULT 'fcm',             -- 'fcm' or 'api'
  
  -- Constraints
  CONSTRAINT chk_status CHECK (status IN ('unread', 'read', 'archived')),
  CONSTRAINT chk_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- Performance indexes
CREATE INDEX idx_status_date ON notifications(status, created_at DESC);
CREATE INDEX idx_type_date ON notifications(type, created_at DESC);
CREATE INDEX idx_unread ON notifications(status, priority, created_at DESC) 
  WHERE status = 'unread';

-- Sync metadata table
CREATE TABLE sync_metadata (
  key TEXT PRIMARY KEY,                  -- 'last_sync_time', 'device_id', etc.
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### Data Models

#### Enhanced NotificationItem
```dart
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledAt;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final String? imageUrl;
  final String? senderId;
  final String? senderName;
  final bool isActionable;
  
  // Local fields
  final DateTime receivedAt;
  final NotificationSource source;
  
  /// Get dynamic action button text based on action_url structure
  String get actionButtonText {
    if (!isActionable || actionUrl == null) return '';
    
    final uri = Uri.tryParse(actionUrl!);
    if (uri == null) return 'Xem chi tiết';
    
    // URL structure mapping to action text
    switch (uri.path) {
      case '/attendance/check-in':
        return 'Chấm công vào';
      case '/attendance/check-out':
        return 'Chấm công ra';
      case '/attendance/supplement':
        return 'Bổ sung chấm công';
      case '/training/register':
        return 'Đăng ký khóa học';
      case '/training/continue':
        return 'Tiếp tục học';
      case '/training/certificate':
        return 'Xem chứng chỉ';
      case '/leave/apply':
        return 'Nộp đơn nghỉ';
      case '/leave/details':
        return 'Xem chi tiết';
      case '/overtime/request':
        return 'Gửi yêu cầu';
      case '/overtime/respond':
        return 'Phản hồi';
      default:
        return _getDefaultTextByType();
    }
  }
  
  /// Fallback action text based on notification type
  String _getDefaultTextByType() {
    switch (type) {
      case NotificationType.attendance:
        return 'Xem chấm công';
      case NotificationType.training:
        return 'Xem khóa học';
      case NotificationType.leave:
        return 'Xem đơn nghỉ';
      case NotificationType.overtime:
        return 'Xem tăng ca';
      case NotificationType.urgent:
        return 'Xử lý ngay';
      case NotificationType.system:
        return 'Xem thông tin';
      default:
        return 'Xem chi tiết';
    }
  }
  
  /// Get appropriate icon based on notification type
  IconData get actionIcon {
    switch (type) {
      case NotificationType.attendance:
        return TablerIcons.clock;
      case NotificationType.training:
        return TablerIcons.book;
      case NotificationType.leave:
        return TablerIcons.calendar;
      case NotificationType.overtime:
        return TablerIcons.clock_hour_9;
      case NotificationType.urgent:
        return TablerIcons.alert_triangle;
      default:
        return TablerIcons.arrow_right;
    }
  }
}

enum NotificationType {
  attendance,   // Chấm công
  training,     // Đào tạo
  leave,        // Nghỉ phép
  overtime,     // Tăng ca
  general,      // Thông báo chung
  system,       // Hệ thống
  urgent,       // Khẩn cấp
}

enum NotificationStatus {
  unread,       // Chưa đọc
  read,         // Đã đọc
  archived,     // Đã lưu trữ
}

enum NotificationPriority {
  low,          // Thấp
  normal,       // Bình thường
  high,         // Cao
  urgent,       // Khẩn cấp
}

enum NotificationSource {
  fcm,          // Từ Firebase push
  api,          // Từ API sync
}
```

#### Simplified Filter Model
```dart
class NotificationFilter {
  final Set<NotificationType> types;
  final Set<NotificationStatus> statuses;
  final NotificationPriority? priority;
  final DateFilter? dateFilter;        // Simple date filtering
  final bool showOnlyUnread;           // Quick toggle

  // Helper methods
  bool get hasActiveFilters => 
    types.isNotEmpty || 
    statuses.isNotEmpty || 
    priority != null ||
    dateFilter != null ||
    showOnlyUnread;
}

enum DateFilter {
  today,        // Hôm nay
  yesterday,    // Hôm qua
  thisWeek,     // Tuần này
}
```

---

## 📱 Implementation Tasks

### Phase 1: Database Layer (Tuần 1)

#### Task 1.1: Database Helper Setup
- [ ] Tạo `DatabaseHelper` class với SQLite integration
- [ ] Implement database schema creation và migration
- [ ] Thêm indexes cho performance
- [ ] Unit tests cho database operations

**Files:**
- `lib/shared/database/database_helper.dart`
- `lib/shared/database/migrations.dart`

#### Task 1.2: Repository Layer
- [ ] Tạo `LocalNotificationRepository`
- [ ] Implement CRUD operations
- [ ] Thêm filtering methods
- [ ] Implement cleanup/maintenance methods

**Files:**
- `lib/features/notifications/data/repositories/local_notification_repository.dart`
- `lib/features/notifications/data/models/notification_extensions.dart`

#### Task 1.3: Model Updates
- [ ] Update `NotificationItem` model với local fields
- [ ] Thêm SQLite serialization methods
- [ ] Update `NotificationFilter` với simplified options

**Files:**
- `lib/features/notifications/data/models/notification_item.dart` (update)

### Phase 2: FCM Integration (Tuần 1)

#### Task 2.1: FCM Message Handling
- [ ] Update `FirebaseService` để lưu notifications vào DB
- [ ] Implement background message handler
- [ ] Handle notification conversion từ FCM to local model
- [ ] Test FCM delivery và storage

**Files:**
- `lib/shared/services/firebase_service.dart` (update)
- `lib/shared/services/notification_handler.dart` (new)

#### Task 2.2: Missed Notifications Sync
- [ ] Implement simple API sync cho missed notifications
- [ ] Thêm sync on app startup
- [ ] Handle merge logic cho local vs server data
- [ ] Add retry mechanism

**Files:**
- `lib/features/notifications/data/repositories/notification_sync_service.dart`

### Phase 3: Enhanced Filtering (Tuần 2)

#### Task 3.1: Updated Filter Model
- [ ] Implement simplified `NotificationFilter`
- [ ] Thêm date filtering logic
- [ ] Update filtering methods trong repository
- [ ] Add filter validation

**Files:**
- `lib/features/notifications/data/models/notification_filter.dart` (new)

#### Task 3.2: Enhanced Filter UI
- [ ] Update `NotificationFilterBottomSheet` với simplified design
- [ ] Thêm quick filter toggles
- [ ] Implement date filter chips
- [ ] Add filter state persistence

**Files:**
- `lib/features/notifications/presentation/widgets/notification_filter_bottom_sheet.dart` (update)
- `lib/features/notifications/presentation/widgets/quick_filter_bar.dart` (new)

### Phase 4: UI Improvements (Tuần 2) ✅ **COMPLETED**

#### Task 4.1: Real-time Updates ✅
- [x] Implement `NotificationBloc` với state management
- [x] Add real-time UI updates khi có notification mới
- [x] Update unread count badge real-time
- [x] Handle notification tap actions
- [x] Error handling với retry logic
- [x] Action success feedback

**Files:**
- `lib/features/notifications/presentation/bloc/notification_bloc.dart` (new)
- `lib/features/notifications/presentation/pages/notification_page.dart` (update)

#### Task 4.2: Enhanced Notification Cards ✅
- [x] Update `NotificationCard` với enhanced design
- [x] Implement dynamic action button với URL structure parsing
- [x] Thêm swipe actions (mark read, delete)
- [x] Implement different styles cho priority levels
- [x] Add attachment/action indicators
- [x] Add contextual icons cho action buttons
- [x] Animated touch feedback
- [x] Enhanced priority styling

**Files:**
- `lib/features/notifications/presentation/widgets/notification_card.dart` (update)

#### Task 4.3: Header Improvements ✅
- [x] Update `NotificationHeader` với enhanced design
- [x] Thêm animated search functionality
- [x] Enhanced unread count badges
- [x] Improved action button layout
- [x] Real-time search with instant results

**Files:**
- `lib/features/notifications/presentation/widgets/notification_header.dart` (update)

### Phase 5: Performance & Polish (Tuần 3)

#### Task 5.1: Performance Optimization
- [ ] Implement pagination cho large notification lists
- [ ] Add image caching cho notification attachments
- [ ] Optimize database queries
- [ ] Add background cleanup jobs

#### Task 5.2: Error Handling & Edge Cases
- [ ] Handle network errors gracefully
- [ ] Implement retry logic cho failed operations
- [ ] Add offline mode support
- [ ] Handle app kill/restart scenarios

#### Task 5.3: Testing & Documentation
- [ ] Unit tests cho all repositories và services
- [ ] Widget tests cho UI components
- [ ] Integration tests cho FCM flow
- [ ] Update documentation

---

## 🎯 Dynamic Action Buttons Strategy

### URL Structure Standard
Để implement dynamic action button text, chúng ta sử dụng **structured action_url** parsing thay vì parsing notification content:

#### Action URL Format
```
/[module]/[action]/[optional_id]
```

#### Predefined Action URLs
```dart
// Attendance actions
'/attendance/check-in'        → 'Chấm công vào'
'/attendance/check-out'       → 'Chấm công ra'  
'/attendance/supplement'      → 'Bổ sung chấm công'

// Training actions
'/training/register'          → 'Đăng ký khóa học'
'/training/continue'          → 'Tiếp tục học'
'/training/certificate'       → 'Xem chứng chỉ'

// Leave actions
'/leave/apply'               → 'Nộp đơn nghỉ'
'/leave/details'             → 'Xem chi tiết'

// Overtime actions
'/overtime/request'          → 'Gửi yêu cầu'
'/overtime/respond'          → 'Phản hồi'
```

#### Implementation Strategy
1. **Primary**: Parse action_url structure (reliable, maintainable)
2. **Fallback**: Default text based on notification type
3. **Future**: Server-defined action text in metadata (v2.0)

#### Example FCM Payload
```json
{
  "notification": {
    "title": "Nhắc nhở chấm công",
    "body": "Bạn chưa chấm công vào hôm nay. Vui lòng chấm công trước 9:00 AM."
  },
  "data": {
    "notification_id": "notif_001",
    "type": "attendance",
    "priority": "high",
    "action_url": "/attendance/check-in",
    "is_actionable": "true"
  }
}
```

#### Action Button Display
- **Text**: Parsed từ action_url structure
- **Icon**: Based on notification type
- **Color**: Based on notification priority
- **Full-width**: Button spans toàn bộ width của card

---

## 🔧 Technical Specifications

### Dependencies
```yaml
dependencies:
  # Database
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # State Management (choose one)
  flutter_bloc: ^8.1.3
  # or provider: ^6.1.1
  
  # JSON & Serialization
  json_annotation: ^4.8.1
  
  # Utils
  collection: ^1.17.2

dev_dependencies:
  # Code Generation
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
  
  # Testing
  mockito: ^5.4.2
  sqlite3_flutter_libs: ^0.5.15
```

### Environment Variables
```dart
// lib/shared/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://api.personaai.com';
  static const String notificationsEndpoint = '/api/v1/notifications';
  static const String syncEndpoint = '/api/v1/notifications/sync';
}
```

### Error Handling Strategy
```dart
class NotificationException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const NotificationException(this.message, {this.code, this.originalError});
}

class NotificationErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    // Log to Firebase Crashlytics
    // Show user-friendly message
    // Retry if appropriate
  }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
- [ ] Database operations (CRUD, filtering, cleanup)
- [ ] Model serialization/deserialization
- [ ] Filter logic và date calculations
- [ ] FCM message parsing
- [ ] Repository methods

### Integration Tests
- [ ] End-to-end FCM flow
- [ ] Database migration scenarios
- [ ] API sync functionality
- [ ] App lifecycle scenarios

### Widget Tests
- [ ] NotificationCard interactions
- [ ] Filter bottom sheet
- [ ] Notification page với different states
- [ ] Real-time update behavior

---

## 🚀 Deployment Plan

### Rollout Strategy
1. **Alpha (Internal)**: Core team testing với limited notifications
2. **Beta (Limited)**: 50 users trong 1 tuần
3. **Staged Rollout**: 25% → 50% → 100% users
4. **Monitoring**: FCM delivery rates, app crashes, user feedback

### Rollback Plan
- Ability to disable new notification system
- Fallback to current mock data system
- Database migration rollback scripts

### Success Metrics
- **FCM Delivery Rate**: >95%
- **App Crash Rate**: <0.1%
- **User Engagement**: >80% notification open rate
- **Performance**: Page load <300ms, memory usage <50MB

---

## 📚 Documentation Updates

### User Documentation
- [ ] Update user guide với new filtering features
- [ ] Create troubleshooting guide
- [ ] Document notification types và actions

### Developer Documentation  
- [ ] API documentation cho sync endpoints
- [ ] Database schema documentation
- [ ] FCM payload format specification
- [ ] Testing guide for notifications

---

## 🎯 Success Criteria

### Functional Requirements
- ✅ Notifications persist across app restarts
- ✅ Real-time updates khi app đang mở
- ✅ Filtering works correctly với all combinations
- ✅ FCM integration hoạt động both foreground/background
- ✅ Missed notifications được sync khi app startup

### Performance Requirements
- ✅ Notification list loads trong <300ms
- ✅ Memory usage <50MB cho 100 notifications
- ✅ Database operations <100ms
- ✅ App startup delay <500ms thêm

### User Experience Requirements
- ✅ Intuitive filtering interface
- ✅ Clear notification status indicators
- ✅ Dynamic, contextual action buttons
- ✅ Smooth scrolling và animations
- ✅ Accessible cho screen readers
- ✅ Works offline (local data)

---

## ⏰ Timeline

| Week | Phase | Deliverables |
|------|-------|-------------|
| Week 1 | Database + FCM | Database layer, FCM integration, basic sync |
| Week 2 | Filtering + UI | Enhanced filtering, improved UI components |
| Week 3 | Polish + Testing | Performance optimization, testing, documentation |

**Total Estimate: 3 weeks (1 developer)**

---

## 🤝 Dependencies & Coordination

### External Dependencies
- Server API endpoints cho sync functionality
- Firebase project configuration
- Push notification certificate setup (iOS)

### Team Coordination
- Backend team: API endpoints specification
- QA team: Testing scenarios và acceptance criteria
- Product team: UX review và approval

---

## 📝 Notes & Considerations

### Technical Debt
- Current mock data system sẽ được replaced
- Existing notification widgets cần updates
- May need database migration từ existing data

### Future Enhancements
- Rich notifications với custom actions
- Notification scheduling
- User preferences cho notification types
- Analytics tracking cho notification engagement

### Risk Mitigation
- Implement feature flags cho gradual rollout
- Maintain backward compatibility during transition
- Have rollback plan sẵn sàng
- Monitor performance metrics closely

---

*Document Version: 1.0*  
*Created: December 2024*  
## ✅ Phase 2 Status Update: FCM Integration COMPLETED

### Achievements
- **Enhanced Firebase Service**: Tích hợp local notifications với FCM messages
- **Background Handler**: Top-level function xử lý notifications khi app background/terminated
- **App Integration**: Real-time callbacks và navigation handling
- **Comprehensive Testing**: 14/14 unit tests passed

### Files Created/Modified
- `lib/shared/services/firebase_service.dart` (enhanced)
- `lib/shared/services/background_message_handler.dart` (new)
- `lib/main.dart` (updated initialization)
- `lib/app_layout.dart` (notification integration)
- `test/firebase_service_test.dart` (comprehensive tests)

### Technical Highlights
- ✅ Foreground/background message handling
- ✅ Local notifications display
- ✅ Database integration với error handling
- ✅ Navigation callbacks và badge updates
- ✅ Background cleanup và maintenance
- ✅ Comprehensive error handling

## ✅ Phase 3 Status Update: Enhanced Filtering COMPLETED

### Achievements
- **Simplified Filter Model**: Complete rewrite với powerful filtering logic
- **Quick Filter Bar**: Horizontal scrollable chips cho common filters  
- **Real Database Integration**: Replaced mock data với actual SQLite operations
- **Enhanced UI Components**: Loading states, error handling, real-time updates
- **Demo Service**: Automatic test data generation cho development

### Files Created/Modified
- `lib/features/notifications/data/models/notification_filter.dart` (new, comprehensive)
- `lib/features/notifications/presentation/widgets/quick_filter_bar.dart` (new)
- `lib/features/notifications/presentation/pages/notification_page.dart` (major update)
- `lib/features/notifications/presentation/widgets/notification_filter_bottom_sheet.dart` (updated)
- `lib/shared/services/notification_demo_service.dart` (new)
- `lib/main.dart` (demo service integration)

### Technical Highlights
- ✅ **Advanced Filtering**: Type, status, priority, date, unread-only, actionable-only filters
- ✅ **Real-time UI Updates**: Database operations với proper error handling
- ✅ **Intelligent Filter Logic**: Efficient matching algorithm với statistics
- ✅ **Quick Action Chips**: Horizontal scrollable filter bar
- ✅ **Loading & Empty States**: Professional UI feedback
- ✅ **Demo Data System**: Automatic test notifications generation
- ✅ **All Tests Passing**: 14/14 tests continue to pass

### Filter Features
- **Quick Filters**: Unread, Actionable, Today, This Week, High/Urgent Priority
- **Type Filters**: Attendance, Training, Leave, Urgent notifications
- **Status Management**: Read/Unread toggle, Mark all read
- **Date Filtering**: Today, Yesterday, This Week với proper date range logic
- **Smart Statistics**: Filter efficiency tracking và breakdown analytics
- **Clear All**: Easy filter reset functionality

### Next Steps
- Ready cho Phase 4: UI Improvements (enhanced cards, real-time updates)
- All database operations functional và tested
- Filter system hoàn chỉnh và scalable

*Last Updated: December 2024* 