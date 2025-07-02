# Database Scripts Directory

Thư mục này chứa các script SQL và tài liệu hướng dẫn cho database PersonaAI.

## 📁 Files

### SQL Scripts
- **[mobile_api_update_fcm_token.sql](./mobile_api_update_fcm_token.sql)** - Function cập nhật FCM token
  - Schema: `mobile_api`
  - Function: `update_fcm_token(fcm_token TEXT)`
  - Purpose: Update FCM token cho push notifications
  - Features: JWT authentication, device headers parsing, UPSERT logic

- **[grant_mobile_api_permissions.sql](./grant_mobile_api_permissions.sql)** - PostgREST Permissions Setup
  - Grant EXECUTE permissions cho `mobile_user` role
  - Required for PostgREST to expose mobile_api functions as RPC endpoints
  - Includes verification script để check permissions

### Documentation
- **[README_fcm_token_integration.md](./README_fcm_token_integration.md)** - FCM Token Integration Guide
  - Deployment instructions
  - Flutter integration code
  - Testing procedures  
  - Security considerations
  - Monitoring & troubleshooting

## 🚀 Quick Apply

### Apply FCM Token Function
```bash
# Connect to database
docker exec -it personaai-postgres psql -U postgres -d personaai

# Apply function
\i docs/db/scripts/mobile_api_update_fcm_token.sql

# Grant PostgREST permissions (IMPORTANT!)
\i docs/db/scripts/grant_mobile_api_permissions.sql

# Verify function và permissions
\df mobile_api.update_fcm_token
SELECT has_function_privilege('mobile_user', 'mobile_api.update_fcm_token(text)', 'execute');
```

### Test Function
```sql
-- Test with sample data
SELECT * FROM mobile_api.update_fcm_token('test_fcm_token_123');

-- Check result
SELECT employee_id, fcm_token, platform, device_id, is_active 
FROM notification.fcm_tokens 
ORDER BY created_date DESC LIMIT 5;
```

## 🔗 Related Documentation

- **[mobile_api_postgrest_guide.md](../mobile_api_postgrest_guide.md)** - Complete mobile API documentation
- **[database_connection_guide.md](../database_connection_guide.md)** - Database connection guide
- **[notification_system.sql](../notification_system.sql)** - Complete notification schema

## 📝 Adding New Scripts

When adding new scripts:
1. Name files descriptively: `schema_function_description.sql`
2. Include header comments with function details
3. Add to this README with description
4. Create integration guide if needed
5. Update main documentation files

---
*Scripts are designed for PersonaAI mobile app backend integration.* 