# Test Security Configuration

## Các tài khoản test:
- **Admin**: username=`admin`, password=`admin123`
- **User**: username=`user`, password=`user123`

## 1. Test Public Endpoints (không cần authentication)

### Health Check (public)
```bash
curl http://localhost:8080/personaai-portal/api/health
```
**Kết quả mong đợi**: ✅ Trả về JSON status mà không cần login

### H2 Console (public - chỉ trong dev mode)
```bash
curl http://localhost:8080/personaai-portal/h2-console
```

### Swagger UI (public)
```bash
curl http://localhost:8080/personaai-portal/swagger-ui.html
```

## 2. Test Protected Endpoints (cần authentication)

### Test endpoint cần authentication (sẽ fail nếu không có auth)
```bash
curl http://localhost:8080/personaai-portal/api/secured/user
```
**Kết quả mong đợi**: ❌ 401 Unauthorized

### Test với authentication - User role
```bash
curl -u user:user123 http://localhost:8080/personaai-portal/api/secured/user
```
**Kết quả mong đợi**: ✅ Trả về thông tin user

### Test với authentication - Admin role  
```bash
curl -u admin:admin123 http://localhost:8080/personaai-portal/api/secured/user
```
**Kết quả mong đợi**: ✅ Trả về thông tin admin

## 3. Test Admin-only Endpoints

### User cố gắng truy cập admin endpoint
```bash
curl -u user:user123 http://localhost:8080/personaai-portal/api/secured/admin
```
**Kết quả mong đợi**: ❌ 403 Forbidden

### Admin truy cập admin endpoint
```bash
curl -u admin:admin123 http://localhost:8080/personaai-portal/api/secured/admin
```
**Kết quả mong đợi**: ✅ Trả về thông tin admin

## 4. Test Security Info
```bash
curl -u admin:admin123 http://localhost:8080/personaai-portal/api/secured/info
```

## 5. All-in-one Test Script

```bash
#!/bin/bash
echo "=== Testing PersonaAI Security Configuration ==="

echo "1. Testing public health endpoint..."
curl -s http://localhost:8080/personaai-portal/api/health | jq .

echo -e "\n2. Testing protected endpoint without auth (should fail)..."
curl -s -w "HTTP Status: %{http_code}\n" http://localhost:8080/personaai-portal/api/secured/user

echo -e "\n3. Testing protected endpoint with user auth..."
curl -s -u user:user123 http://localhost:8080/personaai-portal/api/secured/user | jq .

echo -e "\n4. Testing admin endpoint with user auth (should fail)..."
curl -s -w "HTTP Status: %{http_code}\n" -u user:user123 http://localhost:8080/personaai-portal/api/secured/admin

echo -e "\n5. Testing admin endpoint with admin auth..."
curl -s -u admin:admin123 http://localhost:8080/personaai-portal/api/secured/admin | jq .

echo -e "\n=== Test completed ==="
```

## Cấu hình Security hiện tại:

- **Public endpoints**: `/api/health`, `/actuator/**`, `/swagger-ui/**`, `/h2-console/**`
- **Protected endpoints**: `/api/**` (trừ health)
- **Authentication**: HTTP Basic Auth
- **Users**: 
  - admin/admin123 (ROLE_ADMIN)
  - user/user123 (ROLE_USER)
- **Session**: Stateless (JWT ready) 