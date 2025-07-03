# THIẾT KẾ CƠ SỞ DỮ LIỆU HỆ THỐNG CHẤM CÔNG

## 📋 TỔNG QUAN

Tài liệu này mô tả thiết kế cơ sở dữ liệu cho hệ thống chấm công tích hợp, hỗ trợ:
- **Chấm công qua app mobile** (GPS + WiFi validation)
- **Chấm công qua máy vân tay/khuôn mặt** 
- **Quản lý ca làm việc linh hoạt**
- **Hệ thống nghỉ phép và xin phép trước**
- **Chống gian lận và audit trail**
- **Dedicated columns để tối ưu truy vấn và báo cáo**

---

## 🏗️ KIẾN TRÚC TỔNG QUAN

### **Schema Organization**
```
📦 Database: personaai
├── 🔓 public schema (HR data)
│   ├── employees
│   ├── organizations  
│   ├── job_titles
│   └── ...
└── 🎯 attendance schema (Attendance system)
    ├── 18 tables
    ├── 9 enum types
    └── Performance indexes
```

### **Technology Stack**
- **Database**: PostgreSQL 14+
- **Framework**: Spring Boot với JPA Auditing
- **Mobile**: Flutter với GPS/WiFi detection
- **Integration**: REST APIs cho máy chấm công

### **Database Schema Improvements**
- **Dedicated columns**: Tách dữ liệu từ JSONB sang columns riêng
- **Optimized queries**: Indexes trên GPS, WiFi, session data
- **Backward compatibility**: Vẫn giữ JSONB fields cho legacy support
- **Performance**: Cải thiện tốc độ truy vấn và báo cáo

### **Migration Benefits**
- **Faster queries**: GPS/WiFi queries với B-tree indexes
- **Better reports**: Trực tiếp query columns thay vì parse JSON
- **Type safety**: PostgreSQL type validation cho dữ liệu
- **Easier analytics**: SQL aggregations trên dedicated columns

### **New Performance Indexes**
- **GPS queries**: `idx_device_logs_location` (latitude, longitude)
- **WiFi tracking**: `idx_device_logs_wifi` (wifi_ssid, wifi_bssid)
- **Session linking**: `idx_device_logs_session` (session_id)
- **Shift tracking**: `idx_sessions_shift` (shift_id, work_date)
- **Status queries**: `idx_sessions_status` (status, work_date)
- **Pre-approvals**: `idx_sessions_preapproved` (is_pre_approved, work_date)

---

## 📊 CẤU TRÚC BẢNG DỮ LIỆU

### **1. NHÓM CẤU HÌNH CƠ BẢN**

#### `workplace_locations` - Địa điểm làm việc
```sql
-- Quản lý các văn phòng/chi nhánh với điều kiện chấm công
- GPS validation (latitude, longitude, radius)
- WiFi validation (SSID + BSSID for security)
- Flexible validation modes: strict/ssid_only/gps_only
```

#### `work_shifts` - Ca làm việc
```sql
-- Định nghĩa các ca làm việc linh hoạt
- Hỗ trợ ca qua đêm (overnight shifts)
- Threshold cho late/early leave/overtime
- Days of week configuration (JSON)
```

#### `shift_assignments` - Phân ca làm việc
```sql
-- Phân ca theo hierarchy: department → position → employee
- Priority-based assignment (employee > position > department)
- Date range effectiveness (from/to dates)
- Multi-location support
```

### **2. NHÓM CHẤM CÔNG CORE**

#### `device_logs` - Raw attendance data
```sql
-- Log mọi hoạt động chấm công từ mọi thiết bị
- Dedicated columns: latitude, longitude, gps_accuracy
- WiFi data: wifi_ssid, wifi_bssid for validation
- Tracking fields: source, action, session_id
- Legacy JSONB: device_info, validation_result
- Anti-fraud: risk scoring, suspicious flags
```

#### `attendance_sessions` - Processed sessions
```sql
-- Từng phiên chấm công (check-in/check-out pairs)
- Shift tracking: shift_id, status, is_pre_approved
- Work duration: work_duration_minutes
- Multiple sessions per day support
- Session types: work, break, overtime, meeting
- Auto-calculated duration
```

#### `attendance_records` - Daily summary
```sql
-- Tổng hợp 1 record/ngày/nhân viên
- Calculated work hours, overtime, breaks
- Status determination (normal/late/early_leave)
- Validation workflow
```

### **3. NHÓM NGHỈ PHÉP & XIN PHÉP**

#### `leave_types` - Loại nghỉ phép
```sql
-- Catalog các loại nghỉ phép
- Annual leave, sick leave, maternity, unpaid
- Entitlement rules và approval requirements
```

#### `leave_requests` - Đơn xin nghỉ
```sql
-- Workflow nghỉ phép với approval
- Multi-day leave support
- Supporting documents (JSON)
- Approval chain tracking
```

#### `attendance_preapprovals` - Xin phép trước
```sql
-- Xin phép đến muộn/về sớm/thay đổi lịch
- 6 types: late_arrival, early_leave, schedule_adjustment, 
          extended_break, location_change, overtime_request
- Emergency vs normal approval workflow
- Auto-adjustment when approved
```

### **4. NHÓM AUDIT & COMPLIANCE**

#### `attendance_exceptions` - Giải trình sau
```sql
-- Giải trình các trường hợp bất thường
- Late explanation, missing checkout, location errors
- Supporting evidence (files)
- Manager review workflow
```

#### `attendance_adjustments` - Điều chỉnh dữ liệu
```sql
-- Audit trail cho mọi thay đổi manual
- Field-level change tracking
- Reason và approval tracking
- Full history preservation
```

#### `suspicious_activities` - Phát hiện gian lận
```sql
-- AI/Rule-based fraud detection
- Multiple device usage
- Impossible location jumps
- Time anomalies, suspicious patterns
```

---

## 🔄 DATA FLOW CHÍNH

### **1. CHẤM CÔNG QUA APP MOBILE**

```mermaid
graph TD
    A[Mobile App] --> B[GPS + WiFi Detection]
    B --> C[Validation Logic]
    C --> D[device_logs]
    D --> E[attendance_sessions]
    E --> F[attendance_records]
    F --> G[monthly_summaries]
    
    H[Pre-approvals] --> C
    I[Workplace Rules] --> C
    J[Shift Schedule] --> C
```

**Detailed Flow:**
1. **User Action**: Nhân viên nhấn check-in/out
2. **Location Detection**: App thu thập GPS + WiFi data
3. **Validation**: Kiểm tra workplace_locations rules
4. **Pre-approval Check**: Có pre-approval nào được duyệt không?
5. **Raw Logging**: Ghi vào device_logs (mọi attempt)
6. **Session Processing**: Tạo/update attendance_sessions
7. **Daily Aggregation**: Cập nhật attendance_records
8. **Status Calculation**: Tính late/normal/early_leave

### **2. CHẤM CÔNG QUA MÁY VÂN TAY/KHUÔN MẶT**

```mermaid
graph TD
    A[Physical Device] --> B[Biometric Scan]
    B --> C[Device API]
    C --> D[Sync Service]
    D --> E[device_logs]
    E --> F[attendance_sessions]
    F --> G[attendance_records]
    
    H[Device Status] --> D
    I[Sync Schedule] --> D
```

**Detailed Flow:**
1. **Biometric Scan**: Nhân viên scan vân tay/khuôn mặt
2. **Device Storage**: Lưu tạm trong memory của máy
3. **Sync Process**: API định kỳ đồng bộ về server
4. **Data Validation**: Kiểm tra quality score, duplicate
5. **Integration**: Merge với data từ app (nếu có)
6. **Processing**: Qua cùng pipeline với mobile data

### **3. WORKFLOW XIN PHÉP TRƯỚC**

```mermaid
graph TD
    A[Employee Request] --> B[attendance_preapprovals]
    B --> C[Manager Review]
    C --> D{Approved?}
    D -->|Yes| E[Auto-adjustment Flag]
    D -->|No| F[Rejection Notice]
    E --> G[Actual Check-in/out]
    G --> H[Apply Pre-approval]
    H --> I[attendance_records Update]
```

**Detailed Flow:**
1. **Submit Request**: Nhân viên xin phép qua app
2. **Manager Notification**: Push notification cho manager
3. **Review Process**: Manager approve/reject với comment
4. **Auto-flagging**: Set flag để auto-adjust
5. **Actual Attendance**: Nhân viên chấm công thực tế
6. **Smart Processing**: Hệ thống áp dụng pre-approval
7. **Status Override**: Không bị đánh dấu late/early

### **4. TÍNH TOÁN MONTHLY SUMMARY**

```mermaid
graph TD
    A[attendance_records] --> B[Monthly Job]
    C[public_holidays] --> B
    D[leave_requests] --> B
    E[work_shifts] --> B
    B --> F[monthly_attendance_summaries]
    F --> G[Payroll Export]
```

**Business Logic:**
```sql
-- Tính toán số ngày làm việc thực tế
actual_work_days = present_days - holiday_days

-- Tính tỷ lệ chấm công
attendance_rate = (present_days / total_work_days) * 100

-- Tính tỷ lệ đúng giờ  
punctuality_rate = ((present_days - late_days) / present_days) * 100

-- Tính overtime amount theo ngày lễ
overtime_amount = overtime_hours * hourly_rate * holiday_multiplier
```

---

## 🧠 LOGIC QUAN TRỌNG

### **1. SHIFT ASSIGNMENT RESOLUTION**

**Priority Logic:**
```sql
-- Xác định ca làm việc cho employee vào ngày cụ thể
WITH shift_priority AS (
  SELECT 
    CASE assignment_type 
      WHEN 'employee' THEN 1    -- Highest priority
      WHEN 'position' THEN 2
      WHEN 'department' THEN 3  -- Lowest priority
    END as priority,
    shift_id, location_id
  FROM shift_assignments 
  WHERE target_id = employee_id 
    AND effective_date BETWEEN effective_from AND effective_to
),
shift_exception AS (
  SELECT new_shift_id, new_location_id
  FROM shift_exceptions 
  WHERE assignment_id IN (SELECT id FROM shift_assignments WHERE...)
    AND exception_date = target_date
    AND status = 'approved'
)
SELECT 
  COALESCE(se.new_shift_id, sp.shift_id) as effective_shift,
  COALESCE(se.new_location_id, sp.location_id) as effective_location
FROM shift_priority sp
LEFT JOIN shift_exception se ON true
ORDER BY sp.priority LIMIT 1;
```

### **2. WIFI VALIDATION LOGIC**

**Security-First Approach:**
```json
{
  "validation_modes": {
    "strict": "Require exact SSID + BSSID match",
    "ssid_only": "Allow any BSSID with correct SSID", 
    "flexible": "Try BSSID first, fallback to SSID",
    "gps_only": "Skip WiFi validation entirely"
  }
}
```

**Validation Algorithm:**
```javascript
function validateWiFi(detectedSSID, detectedBSSID, allowedNetworks) {
  const mode = allowedNetworks.validation_mode;
  
  for (let network of allowedNetworks.networks) {
    if (detectedSSID === network.ssid) {
      switch(mode) {
        case 'strict':
          return detectedBSSID === network.bssid;
        case 'ssid_only': 
          return true;
        case 'flexible':
          return network.require_bssid ? 
            detectedBSSID === network.bssid : true;
      }
    }
  }
  return false;
}
```

### **3. FRAUD DETECTION SCORING**

**Risk Calculation:**
```sql
-- Tính risk score cho mỗi attendance event
WITH risk_factors AS (
  SELECT 
    -- Multiple device usage in short time
    CASE WHEN device_count > 1 THEN 30 ELSE 0 END as multi_device_risk,
    
    -- Impossible location jump
    CASE WHEN prev_location_distance > 100 AND time_diff < 3600 
         THEN 50 ELSE 0 END as location_jump_risk,
    
    -- Unusual time patterns
    CASE WHEN check_in_time NOT BETWEEN usual_start - 120 AND usual_start + 120
         THEN 20 ELSE 0 END as time_anomaly_risk,
         
    -- WiFi spoofing indicators
    CASE WHEN wifi_bssid_mismatch THEN 40 ELSE 0 END as wifi_spoof_risk
         
  FROM device_logs_analysis
)
SELECT employee_id, 
       (multi_device_risk + location_jump_risk + 
        time_anomaly_risk + wifi_spoof_risk) as total_risk_score
FROM risk_factors;
```

### **4. HOLIDAY OVERTIME CALCULATION**

**Progressive Rate Logic:**
```sql
-- Tính overtime rate dựa trên loại ngày
WITH daily_rate AS (
  SELECT 
    ar.work_date,
    ar.overtime_minutes,
    COALESCE(ph.overtime_rate, 1.0) as base_rate,
    CASE ph.holiday_type
      WHEN 'national' THEN 3.0    -- 300% for national holidays
      WHEN 'company' THEN 1.5     -- 150% for company holidays  
      WHEN 'regional' THEN 2.0    -- 200% for regional holidays
      ELSE 1.0                    -- Normal day
    END as holiday_multiplier
  FROM attendance_records ar
  LEFT JOIN public_holidays ph 
    ON ar.work_date = ph.holiday_date 
    AND ph.is_active = true
)
SELECT work_date,
       overtime_minutes,
       (overtime_minutes / 60.0) * hourly_wage * base_rate * holiday_multiplier 
       as overtime_amount
FROM daily_rate;
```

---

## 🔐 BẢO MẬT & AUDIT

### **1. Spring Boot Audit Columns**

Mọi bảng (trừ system logs) đều có:
```sql
created_by VARCHAR(50),           -- User tạo record
created_date TIMESTAMP,           -- Thời gian tạo
last_modified_by VARCHAR(50),     -- User sửa lần cuối
last_modified_date TIMESTAMP      -- Thời gian sửa lần cuối
```

### **2. Data Privacy**

**Sensitive Data Protection:**
- GPS coordinates: Chỉ lưu khi cần thiết
- WiFi BSSID: Hash để bảo vệ network info
- Biometric data: Không lưu raw data, chỉ lưu quality score
- Device info: Anonymize device identifiers

### **3. Access Control**

**Role-Based Permissions:**
```sql
-- Manager: Chỉ xem team của mình
WHERE employee_id IN (SELECT id FROM team_members WHERE manager_id = current_user_id)

-- HR: Xem tất cả nhưng không sửa raw data
GRANT SELECT ON attendance.* TO hr_role;
GRANT UPDATE ON attendance.attendance_adjustments TO hr_role;

-- System: Full access cho automated processes
GRANT ALL ON attendance.* TO system_role;
```

---

## 📈 PERFORMANCE OPTIMIZATION

### **1. Indexing Strategy**

**Hot Queries:**
```sql
-- Daily attendance lookup
CREATE INDEX idx_attendance_employee_date 
ON attendance_records (employee_id, work_date);

-- Status filtering
CREATE INDEX idx_attendance_status_date 
ON attendance_records (status, work_date) 
WHERE status != 'normal';

-- Pending approvals
CREATE INDEX idx_preapprovals_pending 
ON attendance_preapprovals (status, submitted_at) 
WHERE status = 'pending';
```

### **2. Partitioning Strategy**

**Time-Based Partitioning:**
```sql
-- Partition device_logs by month (high volume)
CREATE TABLE device_logs_y2024m03 
PARTITION OF device_logs
FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- Partition attendance_records by year
CREATE TABLE attendance_records_2024
PARTITION OF attendance_records  
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

### **3. Data Retention**

**Lifecycle Management:**
```sql
-- Archive old device_logs (keep 2 years)
DELETE FROM device_logs 
WHERE created_at < NOW() - INTERVAL '2 years';

-- Compress old attendance_records (keep 7 years)
-- Move to cold storage after 3 years
```

---

## 🔄 INTEGRATION PATTERNS

### **1. Mobile App Integration**

**API Endpoints:**
```
POST /api/attendance/checkin     - Check-in với GPS/WiFi
POST /api/attendance/checkout    - Check-out
GET  /api/attendance/status      - Current status
POST /api/preapprovals           - Submit pre-approval
GET  /api/preapprovals/pending   - Get pending requests
```

**Real-time Features:**
- WebSocket cho live status updates
- Push notifications cho approvals
- Offline mode với sync khi có network

### **2. Physical Device Integration**

**Sync Protocol:**
```
1. Device → API: POST /api/devices/{id}/sync
2. API validates device authentication
3. Process attendance events batch
4. Return sync status + next sync time
5. Device updates local status
```

**Error Handling:**
- Retry logic cho network failures
- Conflict resolution cho duplicate events
- Device health monitoring

### **3. Payroll System Integration**

**Export Format:**
```json
{
  "period": "2024-03",
  "employees": [
    {
      "employee_id": 123,
      "regular_hours": 168.5,
      "overtime_hours": 12.0,
      "holiday_hours": 8.0,
      "leave_days": 2,
      "deductions": {
        "late_penalties": 50000,
        "absent_days": 1
      },
      "bonuses": {
        "perfect_attendance": 100000
      }
    }
  ]
}
```

---

## 🚀 DEPLOYMENT CONSIDERATIONS

### **1. Database Setup**

**Initial Deployment:**
```bash
# 1. Create schemas and types
psql -f attendance_system.sql

# 2. Setup partitioning
psql -f create_partitions.sql

# 3. Load master data
psql -f load_master_data.sql

# 4. Create application users
psql -f create_users.sql
```

### **2. Monitoring & Alerting**

**Key Metrics:**
- Device sync success rate
- Fraud detection alerts
- API response times
- Database connection pool usage

**Alerts:**
- Multiple failed sync attempts
- High risk score activities
- System downtime during peak hours

### **3. Backup & Recovery**

**Strategy:**
- Daily full backup
- Point-in-time recovery capability  
- Cross-region replication for DR
- Regular restore testing

---

## 📚 APPENDIX

### **A. Enum Types Reference**

```sql
attendance.assignment_type: 'department', 'position', 'employee'
attendance.device_type: 'fingerprint', 'face'
attendance.device_status: 'online', 'offline', 'maintenance'
attendance.check_source: 'app', 'device'
attendance.attendance_status: 'normal', 'late', 'early_leave', 'incomplete', 'absent'
attendance.exception_type: 'late', 'early_leave', 'missing_checkout', 'location_error', 'other'
attendance.approval_status: 'pending', 'approved', 'rejected', 'cancelled'
attendance.summary_status: 'draft', 'locked', 'payroll_sent'
attendance.risk_level: 'low', 'medium', 'high'
attendance.preapproval_request_type: 'late_arrival', 'early_leave', 'schedule_adjustment', 'extended_break', 'location_change', 'overtime_request'
attendance.urgency_level: 'low', 'normal', 'high', 'emergency'
```

### **B. Configuration Settings Reference**

**Core Settings:**
- `max_daily_overtime_hours`: Giới hạn tăng ca/ngày
- `gps_accuracy_threshold`: Độ chính xác GPS tối thiểu
- `auto_checkout_enabled`: Tự động checkout
- `wifi_validation_timeout`: Timeout WiFi validation

**Security Settings:**
- `fraud_detection_enabled`: Bật phát hiện gian lận
- `suspicious_location_threshold`: Ngưỡng vị trí khả nghi
- `wifi_fallback_to_ssid`: Fallback SSID khi BSSID fail

**Approval Settings:**
- `preapproval_auto_apply`: Tự động áp dụng pre-approval
- `preapproval_emergency_threshold`: Thời gian tối thiểu emergency
- `preapproval_max_hours_advance`: Thời gian tối đa xin trước

---

## 📝 REVISION HISTORY

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-03-15 | System Architect | Initial design document |
| 1.1 | 2024-03-15 | System Architect | Added preapprovals & fraud detection |

---

**© 2024 PersonaAI Attendance System. All rights reserved.** 