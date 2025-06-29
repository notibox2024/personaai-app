# PersonaAI Docker Setup

Cấu hình Docker cho PersonaAI bao gồm PostgreSQL, Redis, Keycloak, và PostgREST với xác thực JWT qua JWKS.

## Các dịch vụ

- **PostgreSQL**: Database chính cho PersonaAI và Keycloak
- **Redis**: Cache service  
- **Keycloak**: Identity and Access Management
- **PostgREST**: RESTful API tự động từ PostgreSQL schema với JWKS authentication

## Khởi chạy

### Bước 1: Build Custom Images (lần đầu tiên)

```bash
cd backend/personaai-docker
./scripts/build-custom-images.sh
```

### Bước 2: Khởi chạy Services

```bash
docker-compose up -d
```

**Lưu ý về Custom Keycloak Image:**
- Sử dụng custom image với `curl` để hỗ trợ health checks
- Pre-build với `--health-enabled=true --metrics-enabled=true`
- Tăng security risk nhưng cải thiện monitoring

## Cấu hình Keycloak

### 1. Truy cập Keycloak Admin Console

- **Admin URL**: http://localhost:8080
- **Health Check URL**: http://localhost:9000
- Username: `admin`
- Password: `admin123`

**Lưu ý về Health Checks:**
- Keycloak 26.2 sử dụng port `9000` cho management và health checks
- Health endpoints: `/health`, `/health/ready`, `/health/live`, `/health/started`
- Admin interface vẫn ở port `8080` như thường lệ

### 2. Tạo Realm mới

1. Click "Create Realm"
2. Realm name: `personaai`
3. Click "Create"

### 3. Tạo Client cho PostgREST

1. Vào **Clients** → **Create client**
2. Client ID: `postgrest`
3. Client authentication: `On`
4. Service accounts roles: `On`
5. Click "Save"

### 4. Cấu hình Client

1. Vào tab **Settings**:
   - Access Type: `confidential`
   - Valid Redirect URIs: `*`
   - Web Origins: `*`

2. Vào tab **Credentials**:
   - Lưu lại **Client Secret** để sử dụng

### 5. Tạo User

1. Vào **Users** → **Add user**
2. Username: `testuser`
3. Email: `test@example.com`
4. Click "Create"

5. Vào tab **Credentials**:
   - Set password: `password123`
   - Temporary: `Off`

### 6. Tạo Roles

1. Vào **Realm roles** → **Create role**
2. Role name: `api_user`
3. Click "Save"

4. Assign role to user:
   - Vào **Users** → Select user → **Role mapping**
   - Click "Assign role" → Select `api_user`

## Cấu hình PostgREST với JWKS

### 1. Tự động cấu hình JWKS

Sử dụng script tự động để fetch JWKS từ Keycloak:

```bash
# Tự động fetch và cấu hình JWKS
./scripts/setup-jwt.sh personaai
```

### 2. Cấu hình thủ công (nếu cần)

#### Lấy JWKS từ Keycloak

```bash
curl -s http://localhost:8080/realms/personaai/protocol/openid-connect/certs > jwks.json
```

#### Cấu trúc JWKS

File `jwks.json` có cấu trúc như sau:

```json
{
  "keys": [
    {
      "kid": "key-id",
      "kty": "RSA",
      "alg": "RS256",
      "use": "sig",
      "n": "modulus-value",
      "e": "exponent-value"
    }
  ]
}
```

### 3. Kiểm tra cấu hình

```bash
# Kiểm tra JWKS đã được mount vào container
docker exec personaai-postgrest cat /etc/postgrest/jwks.json

# Restart PostgREST nếu cần
docker-compose restart postgrest
```

## Sử dụng API

### 1. Lấy Access Token

```bash
curl -X POST http://localhost:8080/realms/personaai/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=postgrest" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=testuser" \
  -d "password=password123"
```

### 2. Sử dụng Token với PostgREST

```bash
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  http://localhost:3000/api/verify_jwt
```

## Cấu hình Database Schema

### Tạo bảng mẫu

```sql
-- Connect to personaai database
\c personaai;

-- Create a sample table in api schema
CREATE TABLE api.users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data
INSERT INTO api.users (email, name) VALUES 
  ('john@example.com', 'John Doe'),
  ('jane@example.com', 'Jane Smith');

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON api.users TO authenticated;
GRANT SELECT ON api.users TO web_anon;
GRANT USAGE, SELECT ON SEQUENCE api.users_id_seq TO authenticated;
```

### Test API endpoints

```bash
# Get all users (requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/users

# Create new user (requires auth)
curl -X POST http://localhost:3000/users \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "new@example.com", "name": "New User"}'
```

## Row Level Security (RLS)

Để bảo mật dữ liệu theo user:

```sql
-- Enable RLS on table
ALTER TABLE api.users ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY users_policy ON api.users
  FOR ALL TO authenticated
  USING (email = current_setting('request.jwt.claims')::json->>'email');

-- Grant usage to authenticated role
GRANT SELECT, INSERT, UPDATE, DELETE ON api.users TO authenticated;
```

## Performance Optimization

Hệ thống đã được tối ưu hóa để khởi động nhanh hơn:

### 1. Resource Limits
- **PostgreSQL**: 512MB RAM limit, 256MB reserved
- **Keycloak**: 768MB RAM limit, 384MB reserved  
- **PostgREST**: 256MB RAM limit, 128MB reserved
- **Redis**: 128MB RAM limit, 64MB reserved

### 2. Health Checks Optimization
- Giảm thời gian timeout và interval
- Thêm start_period để tránh false negatives
- Giảm số lần retry

### 3. Keycloak JVM Tuning
```yaml
JAVA_OPTS: "-Xms256m -Xmx512m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m"
```

### 4. JWKS Caching
PostgREST sử dụng JWKS file để cache public keys, giảm thiểu việc gọi API Keycloak.

### 5. Benchmark Startup Performance
```bash
# Đo thời gian khởi động
./scripts/startup-benchmark.sh
```

### 6. Quick Test All Services
```bash
# Test nhanh tất cả services
./scripts/quick-test.sh
```

## Troubleshooting

### Startup Performance Issues

Nếu services khởi động chậm:

1. **Kiểm tra Docker resources**:
```bash
# Kiểm tra memory và CPU usage
docker stats

# Tăng Docker memory limit trong Docker Desktop
# Recommend: ít nhất 4GB RAM
```

2. **Benchmark hiệu suất**:
```bash
./scripts/startup-benchmark.sh
```

3. **Tối ưu máy host**:
- Sử dụng SSD cho Docker volumes
- Tăng RAM allocated cho Docker
- Đóng các ứng dụng không cần thiết

### Kiểm tra logs

```bash
# Xem logs của tất cả services
docker-compose logs

# Xem logs của service cụ thể
docker-compose logs keycloak
docker-compose logs postgrest
docker-compose logs postgres

# Follow logs real-time
docker-compose logs -f [service-name]
```

### Kiểm tra health status

```bash
# PostgreSQL
docker-compose exec postgres pg_isready -U postgres

# Keycloak
curl http://localhost:9000/health/ready

# PostgREST
curl http://localhost:3000/

# Automated health check
./scripts/health-check.sh
```

### JWKS Configuration Issues

1. **JWKS file không tồn tại**:
   ```bash
   # Tạo lại JWKS file
   ./scripts/setup-jwt.sh personaai
   ```

2. **Invalid JWKS format**:
   ```bash
   # Kiểm tra format JWKS
   cat jwks.json | jq .
   
   # Validate JWKS structure
   curl -s http://localhost:8080/realms/personaai/protocol/openid-connect/certs | jq .
   ```

3. **PostgREST không đọc được JWKS**:
   ```bash
   # Kiểm tra file đã được mount
   docker exec personaai-postgrest cat /etc/postgrest/jwks.json
   
   # Restart PostgREST
   docker-compose restart postgrest
   ```

### Reset và khởi tạo lại

```bash
# Stop và xóa containers + volumes
docker-compose down -v

# Xóa images để force rebuild (nếu cần)
docker-compose down --rmi all -v

# Rebuild custom images
./scripts/build-custom-images.sh

# Khởi tạo lại
docker-compose up -d

# Xem quá trình khởi động real-time
docker-compose up
```

### Common Issues

1. **PostgreSQL khởi động chậm**:
   - Kiểm tra init scripts trong `./init-scripts/`
   - Tăng Docker memory allocation
   - Sử dụng SSD cho volumes

2. **Keycloak timeout**:
   - Chờ PostgreSQL ready trước
   - Kiểm tra Java heap settings
   - Tăng `start_period` nếu cần

3. **PostgREST JWT errors**:
   - Kiểm tra JWKS file format
   - Verify key ID (kid) matches
   - Ensure algorithm is RS256

4. **Keycloak health check issues**:
   - **Giải pháp đã áp dụng**: Custom image với curl installed
   - Health check endpoint: `http://localhost:9000/health/ready`
   - JSON response mẫu:
     ```json
     {
       "status": "UP",
       "checks": [
         {
           "name": "Keycloak database connections async health check",
           "status": "UP"
         }
       ]
     }
     ```
   - Để rebuild custom image: `./scripts/build-custom-images.sh`

## Security Notes

⚠️ **Lưu ý bảo mật:**

1. Thay đổi passwords mặc định trong production
2. Sử dụng HTTPS trong production
3. Cấu hình firewall và network security
4. Backup database định kỳ
5. Monitor logs và access patterns
6. Rotate JWKS keys định kỳ

## Environment Variables

Các biến môi trường quan trọng cần thay đổi trong production:

```env
# Keycloak
KEYCLOAK_ADMIN_PASSWORD=strong-password-here

# PostgreSQL
POSTGRES_PASSWORD=strong-db-password

# PostgREST (sử dụng JWKS file)
PGRST_JWT_SECRET=@/etc/postgrest/jwks.json
```

## JWKS Key Rotation

Để rotate keys:

```bash
# 1. Fetch new JWKS từ Keycloak
curl -s http://localhost:8080/realms/personaai/protocol/openid-connect/certs > jwks.json

# 2. Restart PostgREST để load key mới
docker-compose restart postgrest

# 3. Verify key rotation
./scripts/test-jwt.sh
``` 