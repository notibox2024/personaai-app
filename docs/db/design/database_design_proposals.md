# Đề xuất Thiết kế Database cho PersonaAI App

## 1. PHÂN TÍCH HIỆN TẠI

### Database hiện tại
- **File**: `personaai.sql` 
- **Các bảng chính đã có**:
  - `employees` - Thông tin nhân viên
  - `users` - Tài khoản người dùng
  - `organizations` - Cơ cấu tổ chức
  - `job_titles` - Chức danh
  - `roles`, `role_permission` - Phân quyền
  - `attachments` - File đính kèm
  - `audit_log` - Nhật ký hệ thống

### Thiếu sót cần bổ sung
Dựa trên các features trong app, cần bổ sung các nhóm bảng:
1. **Chấm công** (Attendance)
2. **Đào tạo** (Training) 
3. **Thông báo** (Notifications)
4. **Phiên đăng nhập** (Sessions)
5. **Thống kê** (Analytics)
6. **Cấu hình** (Configuration)

---

## 2. ĐỀ XUẤT CÁC BẢNG MỚI

### 2.1. NHÓM CHẤM CÔNG (ATTENDANCE)

#### `attendance_sessions`
```sql
CREATE TABLE attendance_sessions (
  session_id VARCHAR(50) PRIMARY KEY,
  employee_id INT NOT NULL,
  check_in_time TIMESTAMP,
  check_out_time TIMESTAMP,
  session_type attendance_session_type NOT NULL DEFAULT 'normal',
  status attendance_session_status NOT NULL DEFAULT 'pending',
  check_in_location TEXT,
  check_out_location TEXT,
  device_info JSONB,
  notes TEXT,
  is_validated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_attendance_employee 
    FOREIGN KEY (employee_id) REFERENCES employees(emp_id),
  
  -- Indexes
  INDEX idx_attendance_employee_date (employee_id, DATE(check_in_time)),
  INDEX idx_attendance_status (status),
  INDEX idx_attendance_created_at (created_at)
);

-- Enum types
CREATE TYPE attendance_session_type AS ENUM ('normal', 'overtime', 'shift', 'weekend');
CREATE TYPE attendance_session_status AS ENUM ('active', 'completed', 'invalid', 'pending');
```

#### `break_sessions`
```sql
CREATE TABLE break_sessions (
  id VARCHAR(50) PRIMARY KEY,
  attendance_session_id VARCHAR(50) NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  type VARCHAR(20) NOT NULL DEFAULT 'rest', -- 'lunch', 'coffee', 'rest'
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_break_attendance 
    FOREIGN KEY (attendance_session_id) REFERENCES attendance_sessions(session_id)
    ON DELETE CASCADE,
    
  INDEX idx_break_session (attendance_session_id),
  INDEX idx_break_time (start_time)
);
```

#### `location_data`
```sql
CREATE TABLE location_data (
  id SERIAL PRIMARY KEY,
  attendance_session_id VARCHAR(50),
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  accuracy DECIMAL(5,2),
  address TEXT,
  wifi_ssid VARCHAR(100),
  is_in_office_radius BOOLEAN DEFAULT FALSE,
  is_office_wifi BOOLEAN DEFAULT FALSE,
  validation_status location_validation_status DEFAULT 'checking',
  validation_message TEXT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_location_attendance 
    FOREIGN KEY (attendance_session_id) REFERENCES attendance_sessions(session_id)
    ON DELETE CASCADE,
    
  INDEX idx_location_session (attendance_session_id),
  INDEX idx_location_coords (latitude, longitude),
  INDEX idx_location_timestamp (timestamp)
);

CREATE TYPE location_validation_status AS ENUM ('valid', 'invalid', 'warning', 'checking');
```

#### `office_locations`
```sql
CREATE TABLE office_locations (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius_meters DECIMAL(6,2) DEFAULT 100.0,
  address TEXT,
  wifi_ssids TEXT[], -- Array of allowed WiFi SSIDs
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_office_coords (latitude, longitude),
  INDEX idx_office_active (is_active)
);
```

### 2.2. NHÓM ĐÀO TẠO (TRAINING)

#### `courses`
```sql
CREATE TABLE courses (
  id VARCHAR(50) PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  instructor VARCHAR(100),
  thumbnail_url VARCHAR(500),
  duration_minutes INT NOT NULL DEFAULT 0,
  total_lessons INT NOT NULL DEFAULT 0,
  level course_level NOT NULL DEFAULT 'beginner',
  category course_category NOT NULL DEFAULT 'technical',
  rating DECIMAL(2,1) DEFAULT 0.0,
  enrolled_count INT DEFAULT 0,
  price DECIMAL(10,2) DEFAULT 0.00,
  is_free BOOLEAN DEFAULT TRUE,
  tags TEXT[], -- Array of tags
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  INDEX idx_course_category (category),
  INDEX idx_course_level (level),
  INDEX idx_course_active (is_active),
  INDEX idx_course_rating (rating DESC),
  FULLTEXT idx_course_search (title, description)
);

CREATE TYPE course_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');
CREATE TYPE course_category AS ENUM ('technical', 'softSkills', 'leadership', 'compliance', 'safety', 'finance');
```

#### `course_enrollments`
```sql
CREATE TABLE course_enrollments (
  id SERIAL PRIMARY KEY,
  course_id VARCHAR(50) NOT NULL,
  user_id INT NOT NULL,
  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  status training_status DEFAULT 'not_started',
  certificate_issued BOOLEAN DEFAULT FALSE,
  
  CONSTRAINT fk_enrollment_course 
    FOREIGN KEY (course_id) REFERENCES courses(id),
  CONSTRAINT fk_enrollment_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  UNIQUE KEY uk_course_user (course_id, user_id),
  INDEX idx_enrollment_user (user_id),
  INDEX idx_enrollment_status (status)
);

CREATE TYPE training_status AS ENUM ('not_started', 'in_progress', 'completed', 'suspended');
```

#### `training_progress`
```sql
CREATE TABLE training_progress (
  id VARCHAR(50) PRIMARY KEY,
  course_id VARCHAR(50) NOT NULL,
  user_id INT NOT NULL,
  completed_lessons INT DEFAULT 0,
  total_lessons INT DEFAULT 0,
  progress_percentage DECIMAL(5,2) DEFAULT 0.00,
  total_study_minutes INT DEFAULT 0,
  last_accessed_at TIMESTAMP,
  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  status training_status DEFAULT 'not_started',
  
  CONSTRAINT fk_progress_course 
    FOREIGN KEY (course_id) REFERENCES courses(id),
  CONSTRAINT fk_progress_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  UNIQUE KEY uk_progress_course_user (course_id, user_id),
  INDEX idx_progress_user (user_id),
  INDEX idx_progress_status (status),
  INDEX idx_progress_last_accessed (last_accessed_at DESC)
);
```

#### `lesson_progress`
```sql
CREATE TABLE lesson_progress (
  id SERIAL PRIMARY KEY,
  training_progress_id VARCHAR(50) NOT NULL,
  lesson_id VARCHAR(50) NOT NULL,
  title VARCHAR(200),
  is_completed BOOLEAN DEFAULT FALSE,
  watch_time_seconds INT DEFAULT 0,
  total_duration_seconds INT DEFAULT 0,
  progress_percentage DECIMAL(5,2) DEFAULT 0.00,
  completed_at TIMESTAMP,
  
  CONSTRAINT fk_lesson_progress 
    FOREIGN KEY (training_progress_id) REFERENCES training_progress(id)
    ON DELETE CASCADE,
    
  UNIQUE KEY uk_progress_lesson (training_progress_id, lesson_id),
  INDEX idx_lesson_completed (is_completed)
);
```

#### `user_certificates`
```sql
CREATE TABLE user_certificates (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  course_id VARCHAR(50) NOT NULL,
  certificate_url VARCHAR(500),
  certificate_code VARCHAR(50) UNIQUE,
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP,
  is_valid BOOLEAN DEFAULT TRUE,
  
  CONSTRAINT fk_cert_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
  CONSTRAINT fk_cert_course 
    FOREIGN KEY (course_id) REFERENCES courses(id),
    
  INDEX idx_cert_user (user_id),
  INDEX idx_cert_course (course_id),
  INDEX idx_cert_valid (is_valid)
);
```

### 2.3. NHÓM THÔNG BÁO (NOTIFICATIONS)

#### `notifications`
```sql
CREATE TABLE notifications (
  id VARCHAR(50) PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  type notification_type DEFAULT 'general',
  status notification_status DEFAULT 'unread',
  priority notification_priority DEFAULT 'normal',
  created_at BIGINT NOT NULL, -- milliseconds since epoch
  read_at BIGINT,
  scheduled_at BIGINT,
  action_url TEXT,
  metadata JSONB,
  image_url VARCHAR(500),
  sender_id VARCHAR(50),
  sender_name VARCHAR(100),
  is_actionable BOOLEAN DEFAULT FALSE,
  received_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW()) * 1000,
  source VARCHAR(20) DEFAULT 'fcm', -- 'fcm', 'internal', 'system'
  
  INDEX idx_notif_type (type),
  INDEX idx_notif_status (status),
  INDEX idx_notif_priority (priority),
  INDEX idx_notif_created_at (created_at DESC),
  INDEX idx_notif_sender (sender_id)
);

CREATE TYPE notification_type AS ENUM ('attendance', 'training', 'leave', 'overtime', 'general', 'system', 'urgent');
CREATE TYPE notification_status AS ENUM ('unread', 'read', 'archived');
CREATE TYPE notification_priority AS ENUM ('low', 'normal', 'high', 'urgent');
```

#### `notification_recipients`
```sql
CREATE TABLE notification_recipients (
  id SERIAL PRIMARY KEY,
  notification_id VARCHAR(50) NOT NULL,
  user_id INT NOT NULL,
  delivered_at TIMESTAMP,
  read_at TIMESTAMP,
  status delivery_status DEFAULT 'pending',
  
  CONSTRAINT fk_recipient_notification 
    FOREIGN KEY (notification_id) REFERENCES notifications(id)
    ON DELETE CASCADE,
  CONSTRAINT fk_recipient_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  UNIQUE KEY uk_notif_user (notification_id, user_id),
  INDEX idx_recipient_user (user_id),
  INDEX idx_recipient_status (status)
);

CREATE TYPE delivery_status AS ENUM ('pending', 'delivered', 'read', 'failed');
```

#### `firebase_tokens`
```sql
CREATE TABLE firebase_tokens (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  token VARCHAR(500) NOT NULL UNIQUE,
  platform device_platform NOT NULL,
  device_id VARCHAR(100),
  device_name VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_token_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  INDEX idx_token_user (user_id),
  INDEX idx_token_active (is_active),
  INDEX idx_token_platform (platform)
);

CREATE TYPE device_platform AS ENUM ('android', 'ios', 'web');
```

### 2.4. NHÓM PHIÊN ĐĂNG NHẬP (SESSIONS)

#### `user_sessions`
```sql
CREATE TABLE user_sessions (
  session_id VARCHAR(100) PRIMARY KEY,
  user_id INT NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  device_info JSONB,
  ip_address INET,
  user_agent TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  
  CONSTRAINT fk_session_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  INDEX idx_session_user (user_id),
  INDEX idx_session_active (is_active),
  INDEX idx_session_expires (expires_at),
  INDEX idx_session_last_activity (last_activity_at DESC)
);
```

#### `user_devices`
```sql
CREATE TABLE user_devices (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  device_id VARCHAR(100) NOT NULL,
  device_name VARCHAR(100),
  platform VARCHAR(20),
  os_version VARCHAR(50),
  app_version VARCHAR(20),
  last_login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_trusted BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_device_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  UNIQUE KEY uk_user_device (user_id, device_id),
  INDEX idx_device_user (user_id),
  INDEX idx_device_trusted (is_trusted),
  INDEX idx_device_last_login (last_login_at DESC)
);
```

### 2.5. NHÓM THỐNG KÊ (ANALYTICS)

#### `monthly_stats`
```sql
CREATE TABLE monthly_stats (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INT NOT NULL CHECK (year > 2020),
  work_days_completed INT DEFAULT 0,
  total_work_days INT DEFAULT 0,
  remaining_leave_days INT DEFAULT 0,
  total_overtime_hours INT DEFAULT 0,
  performance_rating DECIMAL(3,2) DEFAULT 0.00,
  performance_level VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_stats_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  UNIQUE KEY uk_user_month_year (user_id, month, year),
  INDEX idx_stats_user (user_id),
  INDEX idx_stats_period (year, month)
);
```

#### `user_achievements`
```sql
CREATE TABLE user_achievements (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  achievement_id VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  type achievement_type NOT NULL,
  points INT DEFAULT 0,
  badge_url VARCHAR(500),
  date_earned TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_featured BOOLEAN DEFAULT FALSE,
  
  CONSTRAINT fk_achievement_user 
    FOREIGN KEY (user_id) REFERENCES employees(emp_id),
    
  UNIQUE KEY uk_user_achievement (user_id, achievement_id),
  INDEX idx_achievement_user (user_id),
  INDEX idx_achievement_type (type),
  INDEX idx_achievement_date (date_earned DESC)
);

CREATE TYPE achievement_type AS ENUM ('performance', 'attendance', 'training', 'special');
```

### 2.6. NHÓM CẤU HÌNH (CONFIGURATION)

#### `app_settings`
```sql
CREATE TABLE app_settings (
  id SERIAL PRIMARY KEY,
  key VARCHAR(100) NOT NULL UNIQUE,
  value TEXT,
  type setting_type DEFAULT 'string',
  description TEXT,
  is_system BOOLEAN DEFAULT FALSE,
  is_public BOOLEAN DEFAULT FALSE, -- có thể truy cập từ client
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_by INT,
  
  CONSTRAINT fk_setting_updater 
    FOREIGN KEY (updated_by) REFERENCES employees(emp_id),
    
  INDEX idx_setting_key (key),
  INDEX idx_setting_type (type),
  INDEX idx_setting_public (is_public)
);

CREATE TYPE setting_type AS ENUM ('string', 'number', 'boolean', 'json');
```

#### `feature_flags`
```sql
CREATE TABLE feature_flags (
  id SERIAL PRIMARY KEY,
  feature_name VARCHAR(100) NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT FALSE,
  rollout_percentage INT DEFAULT 0 CHECK (rollout_percentage BETWEEN 0 AND 100),
  target_users INT[], -- Array of specific user IDs
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  description TEXT,
  created_by INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_flag_creator 
    FOREIGN KEY (created_by) REFERENCES employees(emp_id),
    
  INDEX idx_flag_name (feature_name),
  INDEX idx_flag_enabled (is_enabled),
  INDEX idx_flag_dates (start_date, end_date)
);
```

---

## 3. QUAN HỆ GIỮA CÁC BẢNG

### 3.1. Sơ đồ quan hệ chính

```
employees (emp_id)
    ├── attendance_sessions (employee_id)
    │   ├── break_sessions (attendance_session_id)
    │   └── location_data (attendance_session_id)
    ├── course_enrollments (user_id)
    ├── training_progress (user_id)
    │   └── lesson_progress (training_progress_id)
    ├── user_certificates (user_id)
    ├── notification_recipients (user_id)
    ├── firebase_tokens (user_id)
    ├── user_sessions (user_id)
    ├── user_devices (user_id)
    ├── monthly_stats (user_id)
    └── user_achievements (user_id)

courses (id)
    ├── course_enrollments (course_id)
    ├── training_progress (course_id)
    └── user_certificates (course_id)

notifications (id)
    └── notification_recipients (notification_id)
```

### 3.2. Ràng buộc dữ liệu quan trọng

1. **Cascade Delete**:
   - `break_sessions` khi xóa `attendance_sessions`
   - `location_data` khi xóa `attendance_sessions`
   - `lesson_progress` khi xóa `training_progress`
   - `notification_recipients` khi xóa `notifications`

2. **Unique Constraints**:
   - Một user chỉ có một enrollment cho mỗi course
   - Một user chỉ có một training_progress cho mỗi course
   - Device ID unique cho mỗi user
   - Certificate code phải unique

---

## 4. CHỈ MỤC VÀ TỐI ƯU HÓA

### 4.1. Indexes quan trọng

#### Performance Indexes
```sql
-- Attendance queries
CREATE INDEX idx_attendance_employee_date_composite 
ON attendance_sessions (employee_id, DATE(check_in_time), status);

-- Training progress
CREATE INDEX idx_training_user_status_accessed 
ON training_progress (user_id, status, last_accessed_at DESC);

-- Notifications
CREATE INDEX idx_notifications_recipient_status 
ON notification_recipients (user_id, status, delivered_at DESC);

-- Sessions
CREATE INDEX idx_sessions_user_active_expires 
ON user_sessions (user_id, is_active, expires_at);
```

#### Search Indexes
```sql
-- Full-text search cho courses
ALTER TABLE courses ADD FULLTEXT(title, description);

-- JSON indexes cho metadata
CREATE INDEX idx_notifications_metadata_gin 
ON notifications USING GIN (metadata);

CREATE INDEX idx_attendance_device_info_gin 
ON attendance_sessions USING GIN (device_info);
```

### 4.2. Partitioning Strategy

#### Table Partitioning
```sql
-- Partition attendance_sessions by month
CREATE TABLE attendance_sessions_y2024m01 PARTITION OF attendance_sessions
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Partition notifications by creation date
CREATE TABLE notifications_y2024m01 PARTITION OF notifications
FOR VALUES FROM (1704067200000) TO (1706745600000); -- milliseconds
```

---

## 5. MIGRATION STRATEGY

### 5.1. Giai đoạn triển khai

#### Phase 1: Core Features
1. `attendance_sessions`, `break_sessions`, `location_data`
2. `office_locations`
3. `notifications`, `notification_recipients`
4. `firebase_tokens`

#### Phase 2: Training System
1. `courses`, `course_enrollments`
2. `training_progress`, `lesson_progress`
3. `user_certificates`

#### Phase 3: Analytics & Configuration
1. `user_sessions`, `user_devices`
2. `monthly_stats`, `user_achievements`
3. `app_settings`, `feature_flags`

### 5.2. Migration Scripts

#### Script mẫu cho attendance
```sql
-- 001_create_attendance_tables.sql
BEGIN;

-- Create enums
CREATE TYPE attendance_session_type AS ENUM ('normal', 'overtime', 'shift', 'weekend');
CREATE TYPE attendance_session_status AS ENUM ('active', 'completed', 'invalid', 'pending');
CREATE TYPE location_validation_status AS ENUM ('valid', 'invalid', 'warning', 'checking');

-- Create tables
CREATE TABLE attendance_sessions (
  -- Table definition here
);

-- Create indexes
CREATE INDEX idx_attendance_employee_date ON attendance_sessions (employee_id, DATE(check_in_time));

-- Insert sample data if needed
INSERT INTO office_locations (id, name, latitude, longitude, address) VALUES
('main_office', 'Văn phòng chính', 21.0285, 105.8542, 'Nam Từ Liêm, Hà Nội');

COMMIT;
```

### 5.3. Data Migration

#### Migrate từ existing data
```sql
-- Migrate user data to new structure
INSERT INTO user_sessions (session_id, user_id, access_token, refresh_token, expires_at)
SELECT 
  uuid_generate_v4(),
  u.id,
  'temp_token_' || u.id,
  'temp_refresh_' || u.id,
  NOW() + INTERVAL '7 days'
FROM users u
WHERE u.is_active = true;
```

---

## 6. BẢO MẬT VÀ PRIVACY

### 6.1. Data Encryption
- **PII Fields**: `location_data.address`, `device_info`, `user_agent`
- **Sensitive Data**: `access_token`, `refresh_token`

### 6.2. Data Retention
```sql
-- Auto-cleanup old data
CREATE EVENT cleanup_old_sessions
ON SCHEDULE EVERY 1 DAY
DO
  DELETE FROM user_sessions 
  WHERE expires_at < NOW() - INTERVAL 30 DAY;

CREATE EVENT cleanup_old_notifications
ON SCHEDULE EVERY 1 WEEK  
DO
  DELETE FROM notifications 
  WHERE created_at < EXTRACT(EPOCH FROM NOW() - INTERVAL 90 DAY) * 1000
  AND status = 'archived';
```

### 6.3. Access Control
```sql
-- Row Level Security cho notifications
CREATE POLICY notification_access_policy ON notifications
  FOR ALL TO app_user
  USING (
    id IN (
      SELECT notification_id 
      FROM notification_recipients 
      WHERE user_id = current_user_id()
    )
  );
```

---

## 7. MONITORING VÀ MAINTENANCE

### 7.1. Health Check Queries
```sql
-- Check attendance data integrity
SELECT 
  COUNT(*) as invalid_sessions
FROM attendance_sessions 
WHERE check_in_time > check_out_time;

-- Check notification delivery rates
SELECT 
  DATE(FROM_UNIXTIME(created_at/1000)) as date,
  COUNT(*) as total_sent,
  SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as delivered
FROM notification_recipients
GROUP BY DATE(FROM_UNIXTIME(created_at/1000));
```

### 7.2. Performance Monitoring
```sql
-- Slow query analysis
SELECT 
  query_time,
  rows_examined,
  sql_text
FROM mysql.slow_log
WHERE start_time > NOW() - INTERVAL 1 DAY
ORDER BY query_time DESC;
```

---

## 8. FUTURE ENHANCEMENTS

### 8.1. Potential New Features
1. **Leave Management**: Bảng nghỉ phép, approval workflow
2. **Performance Reviews**: Đánh giá định kỳ
3. **Asset Management**: Quản lý tài sản công ty
4. **Document Management**: Tài liệu, policy
5. **Chat/Messaging**: Hệ thống tin nhắn nội bộ

### 8.2. Scalability Considerations
1. **Sharding Strategy**: Chia database theo organization
2. **Read Replicas**: Cho analytics và reports
3. **Caching Layer**: Redis cho sessions, notifications
4. **Archive Strategy**: Move old data to separate tables

---

*Tài liệu này sẽ được cập nhật theo sự phát triển của ứng dụng và feedback từ team development.* 