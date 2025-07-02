# Database Documentation Index

Tổng hợp tất cả tài liệu về database PersonaAI cho việc development và tham khảo.

## 📚 Danh sách tài liệu

### 🚀 Quick Reference
- **[quick_reference.md](./quick_reference.md)** - Tham khảo nhanh các lệnh và thông tin cơ bản
  - Kết nối database
  - Schema notification overview
  - Mobile API (PostgREST) info
  - Lệnh SQL thường dùng

### 🔧 Connection & Setup
- **[database_connection_guide.md](./database_connection_guide.md)** - Hướng dẫn kết nối chi tiết
  - Docker container setup
  - Schema notification (13 objects)
  - Cấu trúc 10 bảng chính + 3 views
  - Templates có sẵn
  - Troubleshooting

### 🌐 API Integration
- **[mobile_api_postgrest_guide.md](./mobile_api_postgrest_guide.md)** - Mobile API & PostgREST
  - Schema mobile_api (5 functions)
  - PostgREST integration architecture
  - JWT authentication flow
  - Usage status & implementation roadmap
  - Security best practices

### 📜 Scripts & Implementation
- **[scripts/](./scripts/)** - Database scripts directory
  - **[mobile_api_update_fcm_token.sql](./scripts/mobile_api_update_fcm_token.sql)** - FCM token update function
  - **[README_fcm_token_integration.md](./scripts/README_fcm_token_integration.md)** - Complete FCM integration guide
  - Ready-to-deploy SQL functions with Flutter examples

## 📊 Database Schemas

### Notification System ✅ ACTIVE
- **Schema**: `notification`
- **Objects**: 13 (10 tables + 3 views)
- **Purpose**: Multi-channel notifications, events, analytics
- **Templates**: 5 ready-to-use templates

### Mobile API Layer ✅ ACTIVE  
- **Schema**: `mobile_api`
- **Objects**: 5 PostgreSQL functions
- **Purpose**: PostgREST API endpoints for mobile app
- **Port**: 3300
- **Used**: 1/5 functions (get_current_user_profile)
- **New**: FCM token update function available

### Other Schemas
- **`attendance`**: 18 tables - Attendance system
- **`public`**: 50 tables - Main business logic
- **`api`**: Available but not documented
- **`auth`**: Available but not documented  
- **`cms_api`**: Available but not documented

## 🗃️ SQL Files

### Schema Definitions
- **[notification_system.sql](./notification_system.sql)** (33KB) - Complete notification schema
- **[attendance_system.sql](./attendance_system.sql)** (36KB) - Attendance system schema
- **[personaai.sql](./personaai.sql)** (532KB) - Full database dump

### Design Documents
- **[attendance_system_design.md](./attendance_system_design.md)** - Attendance system design
- **[database_design_proposals.md](./database_design_proposals.md)** - Database design proposals

## 🔍 How to Use This Documentation

### For New Developers
1. Start with **[quick_reference.md](./quick_reference.md)** để hiểu tổng quan
2. Read **[database_connection_guide.md](./database_connection_guide.md)** để setup kết nối
3. Check **[mobile_api_postgrest_guide.md](./mobile_api_postgrest_guide.md)** để hiểu API integration

### For Feature Development
1. **Notification features** → Xem notification system docs
2. **User profile/auth** → Xem mobile_api functions  
3. **New API endpoints** → Follow PostgREST patterns trong mobile_api guide

### For Database Administration
1. **Connection issues** → database_connection_guide.md troubleshooting section
2. **Schema exploration** → Use quick_reference.md SQL commands
3. **Backup/restore** → database_connection_guide.md procedures

## 🎯 Quick Commands

### Connection
```bash
# Check containers
docker ps | grep postgres

# Connect to database
docker exec personaai-postgres psql -U postgres -d personaai

# Check schemas
\dn
```

### Schema Exploration
```sql
-- List notification tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'notification';

-- List mobile_api functions  
\df mobile_api.*

-- Check templates
SELECT id, name, notification_type FROM notification.notification_templates;
```

## 📝 Contributing

Khi thêm tài liệu mới:
1. Update file README.md này
2. Follow naming convention: `feature_component_guide.md`
3. Include examples và practical usage
4. Add troubleshooting section nếu cần

---
*Cập nhật lần cuối: Documentation được sync với database schema hiện tại* 