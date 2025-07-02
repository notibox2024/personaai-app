# Authentication Silent Refresh Fix

## Vấn đề
Khi `BackgroundTokenRefreshService` thực hiện refresh token tự động, UI của app bị reload/rebuild mặc dù user không thực hiện hành động gì.

## Nguyên nhân
1. Background service gọi `AuthService.refreshToken()`
2. Method này emit state changes qua `authStateStream`
3. AuthBloc listen và emit `AuthAuthenticated` state mới
4. UI rebuild không cần thiết

## Giải pháp

### 1. Silent Refresh Method
Tạo `_performSilentRefreshToken()` trong `AuthService`:

```dart
/// Silent token refresh - không emit state changes khi thành công
Future<bool> _performSilentRefreshToken() async {
  // Chỉ update internal state, KHÔNG emit thông qua stream
  _currentState = AuthStateData.authenticated(session);
  // Chỉ emit khi có lỗi để trigger logout
}
```

### 2. Background Refresh Method
Thêm public method cho background service:

```dart
@override
Future<bool> backgroundRefreshToken() async {
  return await _performSilentRefreshToken();
}
```

### 3. Update Background Service
Sử dụng silent method thay vì normal refresh:

```dart
// Thay đổi từ:
final success = await _authService.refreshToken();

// Thành:
final success = await _authService.backgroundRefreshToken();
```

### 4. Update Auto-refresh Timer
Auto-refresh timer cũng sử dụng silent method:

```dart
Future<void> _performTokenRefresh() async {
  // Sử dụng silent refresh cho auto-refresh
  final success = await _performSilentRefreshToken();
}
```

## Kết quả
- Background token refresh không gây UI reload
- Normal refresh (user-initiated) vẫn emit state changes
- Error cases vẫn được handle đúng (logout khi refresh failed)
- Authentication state consistency được đảm bảo

## Testing
Để test giải pháp:
1. Đăng nhập app
2. Đợi background refresh trigger (mỗi 60 giây)
3. Verify UI không reload khi token refresh thành công
4. Test normal refresh vẫn hoạt động bình thường 