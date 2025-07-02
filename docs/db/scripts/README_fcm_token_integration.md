# FCM Token Integration Guide

## 📋 Tổng quan

Function `mobile_api.update_fcm_token` cho phép app Flutter cập nhật FCM token vào database để sử dụng cho push notifications. Function này tự động lấy thông tin device từ HTTP headers và JWT claims.

## 🚀 Deployment

### 1. Apply Function to Database
```bash
# Kết nối vào database
docker exec -it personaai-postgres psql -U postgres -d personaai

# Apply function
\i /path/to/mobile_api_update_fcm_token.sql
```

### 2. Grant PostgREST Permissions
**Quan trọng**: Function cần được grant quyền cho role `mobile_user` để PostgREST có thể expose:

```bash
# Grant tất cả permissions cho mobile_api schema
docker exec -it personaai-postgres psql -U postgres -d personaai -f /path/to/grant_mobile_api_permissions.sql
```

Hoặc grant manual:
```sql
-- Grant quyền cơ bản
GRANT USAGE ON SCHEMA mobile_api TO mobile_user;
GRANT EXECUTE ON FUNCTION mobile_api.update_fcm_token(TEXT) TO mobile_user;

-- Verify permission
SELECT has_function_privilege('mobile_user', 'mobile_api.update_fcm_token(text)', 'execute');
```

### 3. PostgREST Configuration
Đảm bảo PostgREST được cấu hình đúng:
```yaml
# docker-compose.yml
PGRST_DB_SCHEMAS: mobile_api
PGRST_DB_ANON_ROLE: mobile_user
PGRST_JWT_SECRET: your_jwt_secret_here
```

### 4. Verify Function & Endpoint
```sql
-- Check function exists
\df mobile_api.update_fcm_token

-- Test function (với valid JWT và headers)
SELECT * FROM mobile_api.update_fcm_token('test_fcm_token_123');
```

```bash
# Test PostgREST endpoint
curl -X POST "http://localhost:3300/rpc/update_fcm_token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Device-ID: test-device-123" \
  -H "X-Platform: android" \
  -d '{"p_fcm_token": "test_fcm_token_123"}'
```

## 🔧 Flutter Integration

### 1. Create FCM Token Service

```dart
// lib/features/auth/data/services/fcm_token_service.dart
import 'package:logger/logger.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/firebase_service.dart';

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final Logger _logger = Logger();

  // PostgREST endpoint
  static const String _updateTokenEndpoint = '/rpc/update_fcm_token';

  /// Update FCM token to server
  Future<FcmTokenResult> updateFcmToken() async {
    try {
      _logger.i('Updating FCM token to server');
      
      // Get current FCM token
      final fcmToken = await _firebaseService.getToken();
      if (fcmToken == null) {
        return FcmTokenResult.failure('Không thể lấy FCM token từ Firebase');
      }
      
      // Switch to PostgREST data API
      await _apiService.switchToDataApi();
      
      // Call update function
      final response = await _apiService.post(
        _updateTokenEndpoint,
        data: {'fcm_token': fcmToken},
      );
      
      // Parse response
      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = (response.data as List).first;
        final tokenResponse = FcmTokenResponse.fromJson(result);
        
        if (tokenResponse.success) {
          _logger.i('FCM token updated successfully: ${tokenResponse.message}');
          return FcmTokenResult.success(tokenResponse);
        } else {
          _logger.w('FCM token update failed: ${tokenResponse.message}');
          return FcmTokenResult.failure(tokenResponse.message);
        }
      } else {
        return FcmTokenResult.failure('Invalid response format');
      }
      
    } on ApiException catch (e) {
      _logger.e('API error updating FCM token: ${e.message}');
      return FcmTokenResult.failure('Lỗi API: ${e.message}');
    } catch (e) {
      _logger.e('Unknown error updating FCM token: $e');
      return FcmTokenResult.failure('Lỗi không xác định');
    }
  }

  /// Update token automatically when Firebase token refreshes
  void setupTokenRefreshListener() {
    _firebaseService.onTokenRefresh = (String newToken) async {
      _logger.i('FCM token refreshed, updating to server');
      await updateFcmToken();
    };
  }

  /// Update token after successful login
  Future<void> updateTokenAfterLogin() async {
    // Wait a bit for JWT to be set
    await Future.delayed(const Duration(seconds: 1));
    await updateFcmToken();
  }
}

/// FCM Token Response Model
class FcmTokenResponse {
  final bool success;
  final String message;
  final int? tokenId;
  final int? employeeId;
  final String? deviceId;
  final String? platform;

  const FcmTokenResponse({
    required this.success,
    required this.message,
    this.tokenId,
    this.employeeId,
    this.deviceId,
    this.platform,
  });

  factory FcmTokenResponse.fromJson(Map<String, dynamic> json) {
    return FcmTokenResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      tokenId: json['token_id'],
      employeeId: json['employee_id'],
      deviceId: json['device_id'],
      platform: json['platform'],
    );
  }
}

/// FCM Token Result Wrapper
class FcmTokenResult {
  final bool isSuccess;
  final String message;
  final FcmTokenResponse? data;

  const FcmTokenResult._({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  factory FcmTokenResult.success(FcmTokenResponse data) {
    return FcmTokenResult._(
      isSuccess: true,
      message: data.message,
      data: data,
    );
  }

  factory FcmTokenResult.failure(String message) {
    return FcmTokenResult._(
      isSuccess: false,
      message: message,
    );
  }
}
```

### 2. Integrate into Auth Flow

```dart
// lib/features/auth/data/repositories/auth_repository.dart
// Add to existing AuthRepository

import '../services/fcm_token_service.dart';

class AuthRepository {
  // ... existing code ...
  
  final FcmTokenService _fcmTokenService = FcmTokenService();

  Future<AuthResult<AuthResponse>> login(LoginRequest request) async {
    try {
      // ... existing login logic ...
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Save tokens
        await _tokenManager.saveTokens(authResponse);
        
        // ... existing user session logic ...
        
        // Update FCM token after successful login
        _fcmTokenService.updateTokenAfterLogin();
        
        logger.i('Login successful for user: ${request.username}');
        return AuthResult.success(authResponse);
      }
      
      // ... rest of login method ...
    } catch (e) {
      // ... error handling ...
    }
  }
}
```

### 3. Initialize in App Startup

```dart
// lib/main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize services
  await FirebaseService().initialize();
  await ApiService().initialize();
  
  // Setup FCM token refresh listener
  FcmTokenService().setupTokenRefreshListener();
  
  runApp(MyApp());
}
```

### 4. Optional: Manual Token Update

```dart
// lib/features/settings/presentation/pages/settings_page.dart
class SettingsPage extends StatelessWidget {
  final FcmTokenService _fcmTokenService = FcmTokenService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... UI code ...
      body: Column(
        children: [
          // ... other settings ...
          
          ListTile(
            title: Text('Cập nhật thông báo'),
            subtitle: Text('Đồng bộ cài đặt thông báo với server'),
            trailing: IconButton(
              icon: Icon(Icons.sync),
              onPressed: () async {
                final result = await _fcmTokenService.updateFcmToken();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.isSuccess ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🧪 Testing

### 1. Database Testing
```sql
-- Test function directly
SELECT * FROM mobile_api.update_fcm_token('test_token_12345');

-- Check inserted token
SELECT 
    employee_id, fcm_token, platform, device_id, device_name,
    is_active, created_date, last_used_at
FROM notification.fcm_tokens 
ORDER BY created_date DESC 
LIMIT 5;

-- Test duplicate token handling
SELECT * FROM mobile_api.update_fcm_token('test_token_12345'); -- Same token

-- Test with different device
SELECT * FROM mobile_api.update_fcm_token('new_token_67890');
```

### 2. PostgREST Testing
```bash
# Test with curl (requires valid JWT token)
curl -X POST "http://localhost:3300/rpc/update_fcm_token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-Device-ID: test-device-123" \
  -H "X-Platform: android" \
  -H "X-Device-Name: Test Device" \
  -H "X-Device-Model: Pixel 6" \
  -H "X-OS-Version: Android 13" \
  -H "X-App-Version: 1.0.0" \
  -d '{"fcm_token": "test_fcm_token_123456789"}'
```

### 3. Flutter Integration Testing
```dart
// test/services/fcm_token_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('FcmTokenService Tests', () {
    late FcmTokenService fcmTokenService;
    late MockApiService mockApiService;
    late MockFirebaseService mockFirebaseService;

    setUp(() {
      mockApiService = MockApiService();
      mockFirebaseService = MockFirebaseService();
      fcmTokenService = FcmTokenService();
    });

    test('should update FCM token successfully', () async {
      // Arrange
      when(mockFirebaseService.getToken())
          .thenAnswer((_) async => 'test_fcm_token');
      
      when(mockApiService.post('/rpc/update_fcm_token', data: any))
          .thenAnswer((_) async => Response(
            data: [{
              'success': true,
              'message': 'FCM token được cập nhật thành công',
              'token_id': 123,
              'employee_id': 456,
              'device_id': 'test-device',
              'platform': 'android'
            }],
            statusCode: 200,
          ));

      // Act
      final result = await fcmTokenService.updateFcmToken();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.tokenId, 123);
      verify(mockApiService.switchToDataApi()).called(1);
    });
  });
}
```

## 🔒 Security Considerations

### 1. JWT Validation
- Function sử dụng `SECURITY DEFINER` - chạy với quyền của owner
- Always validate JWT claims và employee existence
- Only active employees can update tokens

### 2. Device ID Generation
- Priority: X-Device-ID header > X-Device-Identifier > User-Agent hash > fallback
- Device ID được hash để bảo mật
- Length limits để prevent overflow attacks

### 3. Token Management
- Automatic deactivation của duplicate tokens
- Reset error count on successful update
- Track last_used_at cho monitoring

## 📊 Monitoring & Analytics

### 1. Database Queries
```sql
-- Active tokens by platform
SELECT platform, COUNT(*) as token_count
FROM notification.fcm_tokens 
WHERE is_active = true 
GROUP BY platform;

-- Recent token updates
SELECT 
    e.full_name,
    ft.platform,
    ft.device_name,
    ft.last_used_at,
    ft.created_date
FROM notification.fcm_tokens ft
JOIN public.employees e ON ft.employee_id = e.id
WHERE ft.is_active = true
ORDER BY ft.last_used_at DESC
LIMIT 20;

-- Token error statistics
SELECT 
    COUNT(*) as total_tokens,
    SUM(CASE WHEN error_count > 0 THEN 1 ELSE 0 END) as tokens_with_errors,
    AVG(error_count) as avg_error_count
FROM notification.fcm_tokens 
WHERE is_active = true;
```

### 2. App Analytics
```dart
// Track FCM token update events
await FirebaseService().logEvent('fcm_token_updated', parameters: {
  'platform': result.data?.platform,
  'success': result.isSuccess,
});
```

## 🚨 Troubleshooting

### Common Issues

1. **JWT Claims Empty**
   - Check JWT token format
   - Verify PostgREST JWT configuration
   - Ensure `request.jwt.claims` setting is available

2. **Employee Not Found**
   - Verify email in JWT matches employee email_internal
   - Check employee is not resigned (date_resign IS NULL)

3. **Headers Not Available**
   - Function fallbacks to User-Agent parsing
   - Check ApiService device headers interceptor
   - Verify PostgREST header forwarding

4. **Token Conflicts**
   - Function handles duplicates automatically
   - Old tokens are deactivated
   - Check unique constraint on employee_id + device_id

### Debug Queries
```sql
-- Check JWT claims processing
SELECT current_setting('request.jwt.claims', true);

-- Check header processing  
SELECT current_setting('request.headers', true);

-- Recent function calls with errors
SELECT message, created_date 
FROM notification.fcm_tokens 
WHERE message LIKE '%Lỗi%' 
ORDER BY created_date DESC;
```

---
*Function này enable push notification infrastructure cho toàn bộ app với automatic device tracking và security.* 