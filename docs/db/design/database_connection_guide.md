# Database Connection Guide - PersonaAI

## 📋 Thông tin kết nối Database

### Docker Container Configuration
```bash
Container Name: personaai-postgres
Database: PostgreSQL 17
Host: localhost
Port: 5432
Username: postgres
Password: postgres
Database Name: personaai
```

### Lệnh kết nối cơ bản
```bash
# Kiểm tra container đang chạy
docker ps | grep postgres

# Kết nối vào database
docker exec -it personaai-postgres psql -U postgres -d personaai

# Chạy lệnh SQL trực tiếp
docker exec personaai-postgres psql -U postgres -d personaai -c "SQL_COMMAND_HERE"
```

## 🗄️ Schema Notification - Tổng quan

Schema `notification` được thiết kế để quản lý hệ thống thông báo đa kênh, sự kiện và phân tích hiệu suất.

### Số liệu thống kê
- **13 objects** trong schema
- **10 bảng chính** (BASE TABLE)
- **3 views** hỗ trợ truy vấn
- **5 templates** thông báo có sẵn

## 📊 Danh sách các bảng chính

### 1. **fcm_tokens** - Quản lý Firebase Tokens
```sql
-- Cấu trúc chính
id, employee_id, fcm_token, platform, device_id, device_name, 
device_model, os_version, app_version, is_active, last_used_at, 
error_count, last_error_message
```
**Mục đích**: Lưu trữ và quản lý FCM tokens cho push notifications
**Indexes**: employee_id, platform, last_used_at
**Constraints**: unique_employee_device

### 2. **notifications** - Bảng thông báo chính
```sql
-- Cấu trúc chính
id, title, message, short_message, notification_type, category, 
priority, action_url, targeting_type, channels, status, 
total_recipients, total_sent, total_delivered, total_read
```
**Mục đích**: Lưu trữ tất cả thông báo trong hệ thống
**Types**: attendance, training, leave, overtime, payroll, meeting, etc.
**Channels**: fcm, email, in_app, sms

### 3. **notification_recipients** - Theo dõi người nhận
```sql
-- Cấu trúc chính
id, notification_id, employee_id, fcm_status, email_status, 
in_app_status, sms_status, first_read_at, first_clicked_at
```
**Mục đích**: Theo dõi trạng thái gửi và đọc theo từng kênh
**Status**: pending, sent, delivered, read, clicked, failed

### 4. **notification_templates** - Template thông báo
```sql
-- Cấu trúc chính
id, name, notification_type, trigger_type, title_template, 
message_template, channels, targeting_type, variables_schema
```
**Mục đích**: Standardize và automation thông báo
**Trigger Types**: manual, scheduled, event_based, workflow

### 5. **events** - Quản lý sự kiện
```sql
-- Cấu trúc chính
id, title, description, start_date, end_date, event_type, 
location, organizer_id, max_participants, status, visibility
```
**Mục đích**: Quản lý lịch và sự kiện công ty
**Types**: meeting, birthday, training, holiday, deadline, etc.

### 6. **event_participants** - Người tham gia sự kiện
```sql
-- Cấu trúc chính
id, event_id, employee_id, response, attendance_status, 
joined_at, left_at
```
**Responses**: pending, accepted, declined, maybe, no_response

### 7. **notification_analytics** - Phân tích hiệu suất
```sql
-- Cấu trúc chính
id, notification_id, total_sent, total_delivered, total_read, 
total_clicked, read_rate, click_rate, calculated_at
```

### 8. **user_notification_preferences** - Cài đặt người dùng
```sql
-- Cấu trúc chính
id, employee_id, notification_type, fcm_enabled, email_enabled, 
in_app_enabled, sms_enabled, quiet_hours_start, quiet_hours_end
```

### 9. **activity_logs** - Nhật ký hoạt động
```sql
-- Cấu trúc chính
id, employee_id, action_type, entity_type, entity_id, 
action_timestamp, ip_address, user_agent
```

### 10. **system_settings** - Cài đặt hệ thống
```sql
-- Cấu trúc chính
setting_key, setting_value, description, is_encrypted, 
last_modified_date, last_modified_by
```

## 📈 Views hỗ trợ

### 1. **user_unread_counts**
```sql
-- Columns: employee_id, total_unread, important_unread, urgent_unread
SELECT * FROM notification.user_unread_counts WHERE employee_id = 1;
```

### 2. **upcoming_events**
```sql
-- Hiển thị sự kiện sắp tới
SELECT * FROM notification.upcoming_events LIMIT 10;
```

### 3. **notification_performance**
```sql
-- Phân tích hiệu suất thông báo
SELECT * FROM notification.notification_performance;
```

## 🎯 Templates có sẵn

| ID | Tên | Loại | Trigger | Status |
|---|---|---|---|---|
| `TMPL_ATTENDANCE_LATE` | Thông báo đi muộn | attendance | manual | ✅ Active |
| `TMPL_LEAVE_APPROVED` | Đơn nghỉ phép được duyệt | leave | manual | ✅ Active |
| `TMPL_BIRTHDAY_REMINDER` | Sinh nhật nhân viên | birthday | manual | ✅ Active |
| `TMPL_MEETING_REMINDER` | Nhắc nhở cuộc họp | meeting | manual | ✅ Active |
| `TMPL_SYSTEM_MAINTENANCE` | Bảo trì hệ thống | system | manual | ✅ Active |

## 🔍 Lệnh SQL thường dùng

### Kiểm tra cấu trúc
```sql
-- Liệt kê tất cả bảng trong schema
SELECT table_name, table_type FROM information_schema.tables 
WHERE table_schema = 'notification' ORDER BY table_type, table_name;

-- Xem cấu trúc bảng
\d+ notification.notifications
\d+ notification.fcm_tokens
```

### Kiểm tra dữ liệu
```sql
-- Đếm records trong các bảng chính
SELECT COUNT(*) FROM notification.notifications;
SELECT COUNT(*) FROM notification.fcm_tokens;
SELECT COUNT(*) FROM notification.notification_templates;

-- Xem templates có sẵn
SELECT id, name, notification_type, is_active 
FROM notification.notification_templates;
```

### Thống kê thông báo
```sql
-- Thông báo theo loại
SELECT notification_type, COUNT(*) 
FROM notification.notifications 
GROUP BY notification_type;

-- Hiệu suất gửi thông báo
SELECT status, COUNT(*) 
FROM notification.notifications 
GROUP BY status;
```

## 🚀 Tính năng chính

### Multi-channel Delivery
- **FCM**: Push notifications cho mobile
- **Email**: Thông báo qua email
- **In-app**: Hiển thị trong ứng dụng
- **SMS**: Tin nhắn (dự phòng)

### Smart Targeting
- **Broadcast**: Gửi toàn bộ
- **Department**: Theo phòng ban
- **Job Level**: Theo cấp bậc
- **Individual**: Cá nhân
- **Custom**: Logic phức tạp

### Automation Features
- **Template-based**: Sử dụng mẫu có sẵn
- **Event-triggered**: Tự động theo sự kiện
- **Scheduled**: Lên lịch gửi
- **Workflow**: Theo quy trình

### Analytics & Tracking
- **Delivery rates**: Tỷ lệ gửi thành công
- **Read rates**: Tỷ lệ đọc
- **Click rates**: Tỷ lệ click
- **Error tracking**: Theo dõi lỗi

## 📝 Ghi chú quan trọng

1. **Time Zone**: Mặc định sử dụng `Asia/Ho_Chi_Minh`
2. **Audit Trail**: Tất cả bảng có Spring Boot Auditing
3. **Soft Delete**: Một số bảng sử dụng flag thay vì xóa thật
4. **Performance**: Đã tối ưu indexes cho query thường dùng
5. **Security**: Các setting quan trọng được mã hóa

## 🔧 Troubleshooting

### Lỗi kết nối thường gặp
```bash
# Container không chạy
docker start personaai-postgres

# Reset password
docker exec -it personaai-postgres psql -U postgres -c "ALTER USER postgres PASSWORD 'postgres';"

# Kiểm tra logs
docker logs personaai-postgres
```

### Backup & Restore
```bash
# Backup schema notification
docker exec personaai-postgres pg_dump -U postgres -d personaai -n notification > notification_backup.sql

# Restore
docker exec -i personaai-postgres psql -U postgres -d personaai < notification_backup.sql
```

---
*Tài liệu này được tạo tự động và cần cập nhật khi có thay đổi cấu trúc database.* 