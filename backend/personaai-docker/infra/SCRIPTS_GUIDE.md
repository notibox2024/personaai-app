# PersonaAI Docker Scripts Guide

Hướng dẫn sử dụng các scripts để quản lý PersonaAI Docker setup với JWKS authentication.

## 📚 Danh sách Scripts

### 1. `setup-jwt.sh` - Cấu hình JWKS Authentication
Thiết lập xác thực JWKS giữa Keycloak và PostgREST.

```bash
# Sử dụng cơ bản
./scripts/setup-jwt.sh

# Với realm tùy chỉnh
./scripts/setup-jwt.sh my-realm
```

**Chức năng:**
- Fetch JWKS từ Keycloak
- Tạo/cập nhật file `jwks.json`
- Restart PostgREST để load keys mới
- Backup file JWKS cũ

### 2. `test-jwt.sh` - Test JWT Authentication
Test xác thực JWT với PostgREST.

```bash
# Sử dụng
./scripts/test-jwt.sh [realm] [username] [password] [client_secret]

# Ví dụ
./scripts/test-jwt.sh personaai testuser password123 "your-client-secret"
```

**Chức năng:**
- Lấy access token từ Keycloak
- Test API calls với valid token
- Test API calls với invalid token
- Hiển thị thông tin token

### 3. `rotate-jwks.sh` - Rotate JWKS Keys
Rotate keys và update JWKS.

```bash
# Sử dụng cơ bản
./scripts/rotate-jwks.sh

# Với realm tùy chỉnh
./scripts/rotate-jwks.sh my-realm
```

**Chức năng:**
- Backup JWKS hiện tại
- Fetch keys mới từ Keycloak
- So sánh và update nếu có thay đổi
- Restart PostgREST
- Dọn dẹp backups cũ (giữ 10 files gần nhất)

### 4. `quick-test.sh` - Quick System Test
Test nhanh toàn bộ hệ thống.

```bash
./scripts/quick-test.sh
```

**Chức năng:**
- Test health của tất cả services
- Kiểm tra JWKS configuration
- Hiển thị resource usage
- Đưa ra next steps

### 5. `build-custom-images.sh` - Build Custom Images
Build custom Keycloak image với health check support.

```bash
./scripts/build-custom-images.sh
```

### 6. `health-check.sh` - Health Check All Services
Kiểm tra health của tất cả services.

```bash
./scripts/health-check.sh
```

## 🚀 Workflow Sử Dụng

### Lần đầu setup:

1. **Build custom images**:
   ```bash
   ./scripts/build-custom-images.sh
   ```

2. **Start services**:
   ```bash
   docker-compose up -d
   ```

3. **Setup Keycloak realm và client** (qua admin console)

4. **Setup JWKS**:
   ```bash
   ./scripts/setup-jwt.sh personaai
   ```

5. **Test authentication**:
   ```bash
   ./scripts/test-jwt.sh personaai testuser password123 "client-secret"
   ```

### Vận hành hàng ngày:

1. **Quick health check**:
   ```bash
   ./scripts/quick-test.sh
   ```

2. **Rotate keys (khi cần)**:
   ```bash
   ./scripts/rotate-jwks.sh personaai
   ```

3. **Test authentication (sau khi rotate)**:
   ```bash
   ./scripts/test-jwt.sh personaai testuser password123 "client-secret"
   ```

## 🔧 File Configuration

### `jwks.json`
File chính chứa JWKS keys:
```json
{
  "keys": [
    {
      "kid": "key-id",
      "kty": "RSA",
      "alg": "RS256",
      "use": "sig",
      "n": "modulus",
      "e": "exponent"
    }
  ]
}
```

### `jwks-backups/`
Thư mục chứa backups của JWKS files với timestamp.

## 🚨 Troubleshooting

### JWKS Issues

1. **JWKS file không tồn tại**:
   ```bash
   ./scripts/setup-jwt.sh personaai
   ```

2. **Keys không match**:
   ```bash
   ./scripts/rotate-jwks.sh personaai
   ```

3. **PostgREST không đọc được JWKS**:
   ```bash
   docker-compose restart postgrest
   ./scripts/quick-test.sh
   ```

### Authentication Issues

1. **Token không valid**:
   - Kiểm tra client secret
   - Kiểm tra user credentials
   - Kiểm tra realm name

2. **PostgREST từ chối token**:
   - Kiểm tra JWKS file
   - Verify key ID match
   - Check algorithm (RS256)

### Restore từ Backup

```bash
# List backups
ls -la jwks-backups/

# Restore from backup
cp jwks-backups/jwks-20240101_120000.json jwks.json
docker-compose restart postgrest
```

## 📊 Monitoring

### Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgrest
docker-compose logs -f keycloak
```

### Resource Usage
```bash
docker stats
```

### Health Status
```bash
./scripts/health-check.sh
```

## 🔐 Security Best Practices

1. **Regular key rotation**:
   - Chạy `rotate-jwks.sh` định kỳ
   - Monitor logs after rotation

2. **Backup management**:
   - Backup được tự động tạo
   - Chỉ giữ 10 backups gần nhất

3. **Monitoring**:
   - Check logs thường xuyên
   - Monitor authentication failures

4. **Production setup**:
   - Change default passwords
   - Use HTTPS
   - Configure proper firewall rules
   - Set up log aggregation

## 🆘 Emergency Procedures

### Service Down

1. **Check container status**:
   ```bash
   docker-compose ps
   ```

2. **Restart specific service**:
   ```bash
   docker-compose restart [service-name]
   ```

3. **Full restart**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Authentication Broken

1. **Restore JWKS**:
   ```bash
   cp jwks-backups/jwks-[latest].json jwks.json
   docker-compose restart postgrest
   ```

2. **Re-setup JWKS**:
   ```bash
   ./scripts/setup-jwt.sh personaai
   ```

3. **Verify**:
   ```bash
   ./scripts/test-jwt.sh personaai testuser password123 "client-secret"
   ``` 