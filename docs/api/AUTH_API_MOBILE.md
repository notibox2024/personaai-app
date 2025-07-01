# Authentication API - Mobile Development Guide

## Tổng quan

API Authentication sử dụng JWT tokens với Keycloak làm Identity Provider. Hỗ trợ đầy đủ authentication flow cho mobile app.

**Base URL:** `/api/v1/auth`

## Endpoints

### 1. Đăng nhập

**POST** `/api/v1/auth/login`

Xác thực người dùng và trả về JWT tokens.

**Request Model:** `LoginRequest`
```json
{
  "username": "string (3-50 ký tự)",
  "password": "string (6-100 ký tự)"
}
```

**Response Model:** `AuthResponse`
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "scope": "openid profile email",
  "session_state": "abc123-def456",
  "issued_at": "2024-01-15T10:30:00Z",
  "expires_at": "2024-01-15T10:35:00Z",
  "refresh_expires_at": "2024-01-15T11:00:00Z"
}
```

### 2. Làm mới token

**POST** `/api/v1/auth/refresh`

Sử dụng refresh token để lấy access token mới.

**Request Model:** `RefreshTokenRequest`
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response Model:** `AuthResponse` (giống như login)

### 3. Đăng xuất

**POST** `/api/v1/auth/logout`

Vô hiệu hóa refresh token.

**Request Model:** `LogoutRequest`
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response:**
```json
{
  "message": "Đăng xuất thành công"
}
```

### 4. Xác thực token

**GET** `/api/v1/auth/validate`

Kiểm tra tính hợp lệ của access token.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "valid": true,
  "message": "Token hợp lệ"
}
```

### 5. Kiểm tra trạng thái token

**POST** `/api/v1/auth/token-status`

Kiểm tra token có hết hạn không.

**Request Model:** `AuthResponse`
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "2024-01-15T10:35:00Z",
  "refresh_expires_at": "2024-01-15T11:00:00Z"
}
```

**Response:**
```json
{
  "accessTokenExpired": false,
  "refreshTokenExpired": false,
  "accessTokenExpiresAt": "2024-01-15T10:35:00Z",
  "refreshTokenExpiresAt": "2024-01-15T11:00:00Z"
}
```

### 6. Health check

**GET** `/api/v1/auth/health`

Kiểm tra trạng thái service.

**Response:**
```json
{
  "status": "UP",
  "service": "AuthenticationService",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Authentication Flow cho Mobile

### Initial Login
1. User nhập username/password
2. Gọi `POST /login` với `LoginRequest`
3. Lưu `access_token` và `refresh_token` từ `AuthResponse`
4. Sử dụng `access_token` trong header cho các API khác

### Token Management
1. Trước mỗi API call, kiểm tra `expires_at`
2. Nếu sắp hết hạn (< 1 phút), gọi `POST /refresh`
3. Nếu refresh failed (401), redirect về login
4. Update tokens mới từ `AuthResponse`

### API Headers
Cho tất cả authenticated requests:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

## Error Codes

| HTTP Code | Error Code | Mô tả |
|-----------|------------|-------|
| 401 | AUTHENTICATION_FAILED | Sai username/password |
| 401 | TOKEN_INVALID | Access token không hợp lệ |
| 401 | TOKEN_REFRESH_FAILED | Refresh token hết hạn |
| 400 | INVALID_REQUEST | Dữ liệu request không hợp lệ |
| 400 | LOGOUT_FAILED | Lỗi khi đăng xuất |

## Model Classes

- **Request Models:** `LoginRequest`, `RefreshTokenRequest`, `LogoutRequest`
- **Response Model:** `AuthResponse`
- **Package:** `com.kienlongbank.personaai.portal.core.data.models.auth`

## Notes cho Mobile Dev

1. **Token Storage:** Lưu tokens trong secure storage (Keychain/KeyStore)
2. **Auto-refresh:** Implement background refresh trước khi token hết hạn
3. **Error Handling:** Xử lý 401 errors để redirect về login
4. **Network:** Retry logic cho network failures
5. **Security:** Không log tokens trong production 