# Database Quick Reference - PersonaAI

## 🚀 Kết nối nhanh
```bash
# Kiểm tra container
docker ps | grep postgres

# Kết nối database
docker exec personaai-postgres psql -U postgres -d personaai -c "SELECT NOW();"

# Liệt kê bảng notification
docker exec personaai-postgres psql -U postgres -d personaai -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'notification';"
```

## 📊 Schema notification - 13 objects

### Bảng chính (10)
- `fcm_tokens` - Firebase tokens
- `notifications` - Thông báo chính  
- `notification_recipients` - Người nhận
- `notification_templates` - Templates (5 mẫu có sẵn)
- `events` - Sự kiện
- `event_participants` - Người tham gia
- `notification_analytics` - Phân tích
- `user_notification_preferences` - Cài đặt user
- `activity_logs` - Nhật ký
- `system_settings` - Cài đặt hệ thống

### Views (3)
- `user_unread_counts` - Đếm chưa đọc
- `upcoming_events` - Sự kiện sắp tới  
- `notification_performance` - Hiệu suất

## 🎯 Templates có sẵn
- `TMPL_ATTENDANCE_LATE` - Đi muộn
- `TMPL_LEAVE_APPROVED` - Nghỉ phép
- `TMPL_BIRTHDAY_REMINDER` - Sinh nhật
- `TMPL_MEETING_REMINDER` - Cuộc họp
- `TMPL_SYSTEM_MAINTENANCE` - Bảo trì

## 🔍 Lệnh thường dùng
```sql
-- Xem cấu trúc bảng
\d+ notification.notifications

-- Đếm records  
SELECT COUNT(*) FROM notification.notification_templates;

-- Kiểm tra templates
SELECT id, name, notification_type FROM notification.notification_templates;

-- View thống kê
SELECT * FROM notification.user_unread_counts LIMIT 5;
```

## 📋 Connection Info
- **Container**: personaai-postgres
- **Host**: localhost:5432
- **User/Pass**: postgres/postgres
- **Database**: personaai
- **Schema**: notification, mobile_api

## 🔗 Mobile API (PostgREST)
- **Port**: 3300 (PostgREST server)
- **Functions**: 4 PostgreSQL functions
- **Authentication**: JWT-based
- **Used**: get_current_user_profile ✅
- **Available**: check_user_permissions, get_team_members, get_organization_tree ⏳ 