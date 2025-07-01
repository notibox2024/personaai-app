# Authentication System Implementation Plan

## Tổng quan dự án

Thực hiện hệ thống authentication hoàn chỉnh cho ứng dụng PersonaAI với token management tự động, sử dụng backend API (Spring Boot + Keycloak) cho authentication và postgREST cho data access.

## Yêu cầu hệ thống

### 1. Architecture Overview
- **Backend API** (getBackendApiUrl): Spring Boot + Keycloak JWT authentication
- **Data API** (getDataApiUrl): postgREST với JWT token authorization  
- **Mobile**: Flutter với automatic token management
- **Storage**: flutter_secure_storage cho tokens, shared_preferences cho metadata

### 2. Core Requirements
- JWT token management (access + refresh)
- Automatic token refresh trước khi hết hạn
- Handle 401 errors từ postgREST
- Secure token storage
- Real authentication với backend API
- Cập nhật auth feature hiện tại

## Phase 1: Data Models & Core Infrastructure

### 1.1 Cập nhật Auth Models

#### `lib/features/auth/data/models/login_request.dart`
```dart
class LoginRequest {
  final String username;
  final String password;
  
  // Validation: username 3-50 chars, password 6-100 chars
  // toJson method
}
```

#### `lib/features/auth/data/models/auth_response.dart`
```dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType; // "Bearer"
  final int expiresIn; // seconds
  final int refreshExpiresIn;
  final String scope;
  final String sessionState;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;
  
  // fromJson, toJson methods
  // Helper methods: isAccessTokenExpired, isRefreshTokenExpired
}
```

#### `lib/features/auth/data/models/refresh_token_request.dart`
```dart
class RefreshTokenRequest {
  final String refreshToken;
}
```

#### `lib/features/auth/data/models/logout_request.dart`
```dart
class LogoutRequest {
  final String refreshToken;
}
```

#### `lib/features/auth/data/models/token_validation_response.dart`
```dart
class TokenValidationResponse {
  final bool valid;
  final String message;
}
```

### 1.2 Tạo Token Manager Service

#### `lib/shared/services/token_manager.dart`
```dart
class TokenManager {
  // Singleton pattern
  // flutter_secure_storage cho tokens
  // shared_preferences cho metadata
  
  // Methods:
  // - saveTokens(AuthResponse)
  // - getAccessToken() -> String?
  // - getRefreshToken() -> String? 
  // - isAccessTokenValid() -> bool
  // - isRefreshTokenValid() -> bool
  // - clearTokens()
  // - getTokenExpirationTime() -> DateTime?
  // - shouldRefreshToken() -> bool (check if expires in < 1 minute)
}
```

### 1.3 Cập nhật API Service

#### `lib/shared/services/api_service.dart`
- Thêm method `setBaseUrl(String url)` để switch giữa backend và data API
- Thêm interceptor cho automatic token injection
- Thêm interceptor cho 401 error handling và auto-refresh
- Thêm interceptor cho device headers injection
- Thêm method `switchToBackendApi()` và `switchToDataApi()`

#### Interceptors Order:
1. **Device Headers Interceptor**: Inject device information headers
2. **Auth Token Interceptor**: Inject valid access token
3. **Error Handling Interceptor**: Handle 401 errors và auto-refresh
4. **Logging Interceptor**: Log requests/responses (debug only)

#### Token Interceptor Logic:
1. Before request: inject valid access token
2. On 401 response: 
   - Try refresh token
   - If refresh success: retry original request
   - If refresh fails: redirect to login

### 1.4 Device Information Service

#### `lib/shared/services/device_info_service.dart`
```dart
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  late final DeviceInfoPlugin _deviceInfo;
  late final NetworkInfo _networkInfo;
  late final Connectivity _connectivity;
  
  // Cached values (initialized once)
  String? _deviceModel;
  String? _osVersion; 
  String? _deviceId;
  String? _brand;
  String? _appVersion;
  String? _buildNumber;
  String? _bundleId;
  String? _sessionId;
  
  Future<void> initialize();
  Future<Map<String, String>> getDeviceHeaders();
  Future<Map<String, String>> getNetworkHeaders();
  Future<Map<String, String>> getAppHeaders();
  Future<Map<String, String>> getUserContextHeaders();
  Future<Map<String, String>> getSessionHeaders();
  Future<Map<String, String>> getAllHeaders();
  
  // Privacy methods
  String _hashDeviceId(String deviceId);
  bool _shouldIncludeLocationHeaders();
  
  // Device ID lifecycle management
  Future<String> _getOrCreateDeviceId();
  Future<void> _cacheDeviceId(String deviceId);
  Future<String?> _getCachedDeviceId();
}
```

### 1.4.1 Device ID Lifecycle Management

#### **Device ID Creation Timeline:**

**iOS (identifierForVendor):**
```dart
// Được tạo bởi iOS:
- First app install từ vendor
- Reset khi: Uninstall ALL apps từ cùng vendor
- Có thể reset: Device restore, iOS update (rare)

// App handling:
DeviceInfoService._getOrCreateDeviceId() {
  1. Get identifierForVendor từ iOS
  2. Nếu null → Generate UUID fallback
  3. Hash với SHA-256 + app salt
  4. Cache trong SharedPreferences
  5. Return hashed ID
}
```

**Android (androidId):**
```dart
// Được tạo bởi Android:
- Device first boot/setup
- Reset khi: Factory reset, custom ROM
- Stable: Across app installs/uninstalls

// App handling:
DeviceInfoService._getOrCreateDeviceId() {
  1. Get androidId từ Settings.Secure
  2. Nếu null/empty → Generate UUID fallback  
  3. Hash với SHA-256 + app salt
  4. Cache trong SharedPreferences
  5. Return hashed ID
}
```

#### **Fallback Strategies:**
```dart
// Khi OS device ID không available:
1. Check cached device ID trong SharedPreferences
2. Generate new UUID + timestamp
3. Store trong SharedPreferences
4. Hash và return

// Consistency checks:
- App startup: Compare OS ID vs cached ID
- Nếu khác nhau: Update cache, log event
- Privacy: Always hash trước khi gửi server
```

#### **Implementation Details:**

```dart
class DeviceInfoService {
  static const String _deviceIdKey = 'cached_device_id';
  static const String _deviceIdSalt = 'personaai_device_salt_2024';
  
  Future<String> _getOrCreateDeviceId() async {
    try {
      // 1. Try to get OS device ID
      String? osDeviceId = await _getOSDeviceId();
      
      // 2. Check cached ID
      String? cachedId = await _getCachedDeviceId();
      
      // 3. Validate consistency
      if (osDeviceId != null && cachedId != null) {
        String hashedOsId = _hashDeviceId(osDeviceId);
        if (hashedOsId != cachedId) {
          // OS ID changed, update cache
          await _cacheDeviceId(hashedOsId);
          FirebaseService().log('Device ID changed: OS ID updated');
          return hashedOsId;
        }
        return cachedId;
      }
      
      // 4. Create new ID if needed
      if (osDeviceId != null) {
        String hashedId = _hashDeviceId(osDeviceId);
        await _cacheDeviceId(hashedId);
        return hashedId;
      }
      
      // 5. Fallback to UUID
      if (cachedId != null) return cachedId;
      
      String fallbackId = _generateFallbackId();
      String hashedFallback = _hashDeviceId(fallbackId);
      await _cacheDeviceId(hashedFallback);
      FirebaseService().log('Device ID fallback generated');
      
      return hashedFallback;
      
    } catch (e) {
      // 6. Emergency fallback
      String emergencyId = 'emergency_${DateTime.now().millisecondsSinceEpoch}';
      return _hashDeviceId(emergencyId);
    }
  }
  
  Future<String?> _getOSDeviceId() async {
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.androidId;
    }
    return null;
  }
  
  String _generateFallbackId() {
    final uuid = Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${uuid}_$timestamp';
  }
  
  String _hashDeviceId(String deviceId) {
    final bytes = utf8.encode(deviceId + _deviceIdSalt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  Future<void> _cacheDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
  }
  
  Future<String?> _getCachedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }
}
```

### 1.5 Enhanced API Service Implementation

#### Complete `lib/shared/services/api_service.dart` Update
```dart
class ApiService {
  late final Dio _dio;
  late final DeviceInfoService _deviceInfoService;
  late final TokenManager _tokenManager;
  late final AuthService _authService;
  final logger = Logger();
  
  void initialize({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    _deviceInfoService = DeviceInfoService();
    _tokenManager = TokenManager();
    _authService = AuthService();
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    
    _setupAllInterceptors();
  }
  
  void _setupAllInterceptors() {
    // 1. Device Headers Interceptor (always first)
    _dio.interceptors.add(_createDeviceHeadersInterceptor());
    
    // 2. Auth Token Interceptor
    _dio.interceptors.add(_createAuthTokenInterceptor());
    
    // 3. Error Handling Interceptor (401 retry logic)
    _dio.interceptors.add(_createErrorHandlingInterceptor());
    
    // 4. Logging Interceptor (debug only, always last)
    if (kDebugMode) {
      _dio.interceptors.add(_createLoggingInterceptor());
    }
  }
  
  // Device Headers Interceptor
  Interceptor _createDeviceHeadersInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          if (FirebaseService().getConfigBool(RemoteConfigKeys.enableDeviceHeaders)) {
            final deviceHeaders = await _deviceInfoService.getAllHeaders();
            options.headers.addAll(deviceHeaders);
          }
        } catch (e) {
          logger.w('Failed to add device headers: $e');
        }
        handler.next(options);
      },
    );
  }
  
  // Auth Token Interceptor
  Interceptor _createAuthTokenInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _authService.ensureValidToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          logger.e('Failed to add auth token: $e');
        }
        handler.next(options);
      },
    );
  }
  
  // Error Handling Interceptor
  Interceptor _createErrorHandlingInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            logger.i('Received 401, attempting token refresh...');
            
            final refreshed = await _authService.refreshToken();
            if (refreshed) {
              // Retry original request with new token
              final newToken = await _tokenManager.getAccessToken();
              if (newToken != null) {
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                
                logger.i('Retrying request with new token...');
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              }
            }
          } catch (e) {
            logger.e('Token refresh failed: $e');
          }
          
          // If refresh failed, logout user
          await _authService.logout();
        }
        handler.next(error);
      },
    );
  }
  
  // Logging Interceptor
  Interceptor _createLoggingInterceptor() {
    return LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => logger.i(obj.toString()),
    );
  }
  
  // Switch between Backend API and Data API
  void switchToBackendApi() {
    final backendUrl = FirebaseService().getBackendApiUrl();
    _dio.options.baseUrl = backendUrl;
    logger.i('Switched to Backend API: $backendUrl');
  }
  
  void switchToDataApi() {
    final dataUrl = FirebaseService().getDataApiUrl();
    _dio.options.baseUrl = dataUrl;
    logger.i('Switched to Data API: $dataUrl');
  }
  
  // Set custom base URL
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }
}
```

## Phase 2: Authentication Service Layer

### 2.1 Cập nhật Auth Repository

#### `lib/features/auth/data/repositories/auth_repository.dart`
```dart
class AuthRepository {
  final ApiService _apiService;
  final TokenManager _tokenManager;
  final FirebaseService _firebaseService;
  
  // Methods:
  // - login(LoginRequest) -> AuthResponse
  // - refreshToken(String) -> AuthResponse  
  // - logout(String) -> void
  // - validateToken(String) -> TokenValidationResponse
  // - checkTokenStatus(AuthResponse) -> TokenStatusResponse
  // - isLoggedIn() -> bool
  // - getCurrentUser() -> UserSession?
}
```

### 2.2 Tạo Auth Service

#### `lib/shared/services/auth_service.dart`
```dart
class AuthService {
  // High-level authentication service
  // Combines AuthRepository + TokenManager
  
  // Methods:
  // - initialize() -> bool (check existing tokens)
  // - login(username, password) -> Result<UserSession>
  // - logout() -> void
  // - autoRefreshToken() -> void (background timer)
  // - ensureValidToken() -> Future<String?> (for API calls)
  // - isAuthenticated() -> bool
  // - onAuthStateChanged -> Stream<AuthState>
}
```

### 2.3 Auth State Management

#### `lib/features/auth/data/models/auth_state.dart`
```dart
enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  refreshing,
  error
}

class AuthStateData {
  final AuthState state;
  final UserSession? user;
  final String? error;
}
```

## Phase 3: UI Layer Updates

### 3.1 Cập nhật Auth Pages

#### `lib/features/auth/presentation/pages/login_page.dart`
- Sử dụng LoginRequest model
- Call real API thông qua AuthRepository
- Handle loading, error states
- Navigate on success

#### `lib/features/auth/presentation/widgets/login_form.dart`
- Validation theo spec (username 3-50, password 6-100)
- Error handling UI
- Loading states

### 3.2 Tạo Auth Guard

#### `lib/shared/widgets/auth_guard.dart`
```dart
class AuthGuard extends StatelessWidget {
  // Wrapper widget check authentication
  // Redirect to login if not authenticated
  // Show loading while checking tokens
}
```

## Phase 4: Integration & Background Services

### 4.1 App Initialization

#### `lib/main.dart`
```dart
// Initialize services in order:
// 1. Firebase (existing)
// 2. DeviceInfoService (collect device information)
// 3. TokenManager (secure storage setup)
// 4. AuthService (authentication logic)
// 5. ApiService with all interceptors (device headers + auth + error handling)
// 6. Check existing authentication state
```

#### Initialization Flow:
```dart
Future<void> initializeServices() async {
  // 1. Firebase
  await Firebase.initializeApp();
  await FirebaseService().initialize();
  
  // 2. Device Info (cache device information)
  await DeviceInfoService().initialize();
  
  // 3. Token Manager
  await TokenManager().initialize();
  
  // 4. Auth Service
  await AuthService().initialize();
  
  // 5. API Service with interceptors
  ApiService().initialize(
    baseUrl: FirebaseService().getBackendApiUrl(),
    interceptors: [
      DeviceHeadersInterceptor(),
      AuthTokenInterceptor(),
      ErrorHandlingInterceptor(),
      if (kDebugMode) LoggingInterceptor(),
    ],
  );
  
  // 6. Check authentication state
  final isAuthenticated = await AuthService().checkAuthenticationState();
  if (!isAuthenticated) {
    // Navigate to login
  }
}
```

### 4.2 Background Token Refresh

#### Timer-based refresh:
- Check token expiration mỗi 1 phút
- Auto-refresh khi còn < 2 phút
- Handle refresh failures gracefully

### 4.3 App State Management

#### Update `lib/app_layout.dart`:
- Integrate AuthGuard
- Handle auth state changes
- Show login when unauthenticated

## Phase 5: Data API Integration

### 5.1 Authenticated API Service Base

#### `lib/shared/services/authenticated_api_service.dart`
```dart
abstract class AuthenticatedApiService {
  final ApiService _apiService;
  final TokenManager _tokenManager;
  final AuthService _authService;
  
  AuthenticatedApiService(this._apiService, this._tokenManager, this._authService);
  
  // Base methods cho authenticated requests
  Future<Response<T>> authenticatedGet<T>(String path, {Map<String, dynamic>? queryParameters});
  Future<Response<T>> authenticatedPost<T>(String path, {dynamic data});
  Future<Response<T>> authenticatedPut<T>(String path, {dynamic data});
  Future<Response<T>> authenticatedDelete<T>(String path, {dynamic data});
  
  // Switch to Data API (postgREST)
  Future<void> _ensureDataApiMode();
  
  // Handle authentication cho từng request
  Future<void> _ensureAuthenticated();
}
```

#### `lib/shared/services/data_api_mixin.dart`
```dart
mixin DataApiMixin on AuthenticatedApiService {
  // Common postgREST utilities
  Map<String, String> get commonHeaders;
  String buildPostgRestQuery(Map<String, dynamic> filters);
  Map<String, dynamic> handlePostgRestResponse(Response response);
}
```

### 5.2 Repository Updates với Authentication

Thay vì tạo một DataService tập trung, chúng ta sẽ cập nhật từng repository để extend AuthenticatedApiService:

#### `lib/features/home/data/repositories/home_repository.dart`
```dart
class HomeRepository extends AuthenticatedApiService with DataApiMixin {
  HomeRepository(super.apiService, super.tokenManager, super.authService);
  
  // Existing methods với authentication
  Future<EmployeeInfo> getEmployeeInfo() async {
    await _ensureDataApiMode();
    final response = await authenticatedGet<Map<String, dynamic>>('/employee_info');
    return EmployeeInfo.fromJson(response.data!);
  }
  
  Future<List<AttendanceInfo>> getAttendanceHistory() async {
    await _ensureDataApiMode();
    final response = await authenticatedGet<List<dynamic>>('/attendance_records');
    return response.data!.map((json) => AttendanceInfo.fromJson(json)).toList();
  }
}
```

#### `lib/features/attendance/data/repositories/attendance_repository.dart`
```dart
class AttendanceRepository extends AuthenticatedApiService with DataApiMixin {
  AttendanceRepository(super.apiService, super.tokenManager, super.authService);
  
  Future<AttendanceSession> checkIn(LocationData location) async {
    await _ensureDataApiMode();
    final response = await authenticatedPost<Map<String, dynamic>>(
      '/attendance_sessions',
      data: {
        'action': 'check_in',
        'location': location.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    return AttendanceSession.fromJson(response.data!);
  }
  
  Future<AttendanceSession> checkOut() async {
    await _ensureDataApiMode();
    final response = await authenticatedPost<Map<String, dynamic>>(
      '/attendance_sessions',
      data: {
        'action': 'check_out',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    return AttendanceSession.fromJson(response.data!);
  }
}
```

#### `lib/features/notifications/data/repositories/notification_repository.dart`
```dart
class NotificationRepository extends AuthenticatedApiService with DataApiMixin {
  NotificationRepository(super.apiService, super.tokenManager, super.authService);
  
  Future<List<NotificationItem>> getNotifications({
    NotificationFilter? filter,
    int? limit,
    int? offset,
  }) async {
    await _ensureDataApiMode();
    
    final queryParams = <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
    
    if (filter != null) {
      queryParams.addAll(filter.toQueryParams());
    }
    
    final response = await authenticatedGet<List<dynamic>>('/notifications', queryParameters: queryParams);
    return response.data!.map((json) => NotificationItem.fromJson(json)).toList();
  }
  
  Future<void> markAsRead(String notificationId) async {
    await _ensureDataApiMode();
    await authenticatedPut<Map<String, dynamic>>(
      '/notifications',
      data: {
        'id': 'eq.$notificationId',
        'status': NotificationStatus.read.name,
        'read_at': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

#### `lib/features/profile/data/repositories/profile_repository.dart`
```dart
class ProfileRepository extends AuthenticatedApiService with DataApiMixin {
  ProfileRepository(super.apiService, super.tokenManager, super.authService);
  
  Future<UserProfile> getUserProfile() async {
    await _ensureDataApiMode();
    final response = await authenticatedGet<Map<String, dynamic>>('/user_profiles');
    return UserProfile.fromJson(response.data!);
  }
  
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await _ensureDataApiMode();
    final response = await authenticatedPut<Map<String, dynamic>>(
      '/user_profiles',
      data: profile.toJson(),
    );
    return UserProfile.fromJson(response.data!);
  }
}
```

## Phase 6: Error Handling & User Experience

### 6.1 Error Handling Strategy

#### Network Errors:
- Connection timeout: Show retry dialog
- Server errors: Show user-friendly messages
- 401 errors: Auto-refresh or redirect to login

#### Token Expiration:
- Background refresh: Transparent to user
- Refresh failure: Show login prompt
- Offline mode: Use cached data

### 6.2 User Experience Improvements

#### Loading States:
- Splash screen với token validation
- Shimmer loading cho authenticated screens
- Progress indicators cho login

#### Error Messages:
- Vietnamese error messages
- Specific error handling cho từng case
- Retry mechanisms

## Phase 7: Security & Storage

### 7.1 Secure Storage Implementation

#### flutter_secure_storage:
```dart
// Keys:
- 'access_token'
- 'refresh_token'
- 'token_expires_at'
- 'refresh_expires_at'
```

#### shared_preferences:
```dart
// Keys:
- 'user_id'
- 'username'
- 'last_login'
- 'auto_login_enabled'
- 'biometric_enabled'
```

### 7.2 Security Best Practices

- Không log tokens trong production
- Clear tokens khi logout
- Validate token format
- Handle token tampering
- Biometric authentication (future)

## Phase 8: Testing Strategy

### 8.1 Unit Tests

#### Test files cần tạo:
- `test/auth/auth_repository_test.dart`
- `test/services/token_manager_test.dart`
- `test/services/auth_service_test.dart`
- `test/models/auth_models_test.dart`

#### Test scenarios:
- Login success/failure
- Token refresh logic
- Error handling
- Model serialization

### 8.2 Integration Tests

#### API Integration:
- Login flow end-to-end
- Token refresh automation
- 401 error handling
- Logout cleanup

### 8.3 Widget Tests

- Login form validation
- Loading states
- Error message display
- Navigation flows

## Implementation Timeline

### Week 1: Core Infrastructure
- [ ] Models (LoginRequest, AuthResponse, etc.)
- [ ] TokenManager service
- [ ] DeviceInfoService implementation
- [ ] Updated ApiService với all interceptors (device headers + auth + error handling)
- [ ] Basic AuthRepository

### Week 2: Authentication Logic  
- [ ] AuthService với auto-refresh
- [ ] Auth state management
- [ ] Error handling strategies
- [ ] Secure storage implementation

### Week 3: UI Integration
- [ ] Updated login pages
- [ ] AuthGuard component
- [ ] App initialization flow
- [ ] Loading và error states

### Week 4: Data Integration
- [ ] DataService cho postgREST
- [ ] Repository updates
- [ ] Background refresh service
- [ ] End-to-end testing

### Week 5: Testing & Polish
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Documentation updates

## Migration Plan

### Từ Demo Auth sang Real Auth:

1. **Backup**: Commit current demo auth state
2. **Models**: Create new models trong auth/data/models  
3. **Services**: Implement TokenManager và AuthService
4. **Repository**: Update AuthRepository từng method
5. **UI**: Update login pages dần dần
6. **Testing**: Test từng component before integration
7. **Switch**: Chuyển từ demo sang real auth
8. **Cleanup**: Remove demo code

### Rollback Strategy:

- Keep demo auth code during transition
- Feature flags để switch between demo/real auth
- Database migration cho user sessions
- Graceful error fallback to demo auth

## Configuration

### Environment Variables:
```dart
// lib/shared/constants/api_constants.dart
class ApiConstants {
  static const String authApiBase = 'BACKEND_API_URL';
  static const String dataApiBase = 'DATA_API_URL';
  static const Duration tokenRefreshThreshold = Duration(minutes: 2);
  static const Duration autoRefreshInterval = Duration(minutes: 1);
}
```

### Remote Config Keys:
```dart
// lib/shared/constants/remote_config_keys.dart
class RemoteConfigKeys {
  // Authentication
  static const String enableAutoRefresh = 'enable_auto_refresh';
  static const String refreshThresholdMinutes = 'refresh_threshold_minutes';
  static const String maxRetryAttempts = 'max_retry_attempts';
  static const String enableBiometric = 'enable_biometric_auth';
  
  // Device Headers
  static const String enableDeviceHeaders = 'enable_device_headers';
  static const String enableNetworkHeaders = 'enable_network_headers';
  static const String enableLocationHeaders = 'enable_location_headers';
  static const String enableIpTracking = 'enable_ip_tracking';
  static const String deviceHeadersConfig = 'device_headers_config';
  
  // Default values
  static const Map<String, dynamic> defaultValues = {
    // Auth defaults
    'enable_auto_refresh': true,
    'refresh_threshold_minutes': 2,
    'max_retry_attempts': 3,
    'enable_biometric_auth': false,
    
    // Device headers defaults
    'enable_device_headers': true,
    'enable_network_headers': true,
    'enable_location_headers': false,
    'enable_ip_tracking': false,
    'device_headers_config': {
      'include_device_model': true,
      'include_os_version': true,
      'include_app_version': true,
      'hash_device_id': true,
    },
  };
}
```

## Success Criteria

### Technical:
- [ ] 100% automated token management
- [ ] Zero 401 errors due to expired tokens  
- [ ] < 2s login response time
- [ ] Offline capability với cached tokens
- [ ] 95% test coverage cho auth logic

### User Experience:
- [ ] Seamless authentication flow
- [ ] No interruptions từ token expiration
- [ ] Clear error messages in Vietnamese
- [ ] Fast app startup với existing tokens
- [ ] Secure logout clears all data

### Security:
- [ ] Tokens stored securely
- [ ] No token leakage trong logs
- [ ] Proper token validation
- [ ] Secure transmission over HTTPS
- [ ] Handle edge cases gracefully

---

## Notes cho Developer

1. **Testing Environment**: Setup test backend với valid JWT tokens
2. **Error Scenarios**: Test network failures, server errors, invalid tokens
3. **Performance**: Monitor token refresh frequency và API response times
4. **Security**: Regular security audit cho token handling
5. **Documentation**: Update API documentation khi có thay đổi

### Device Headers Testing

6. **Device Headers Validation**: Test với different devices/platforms để đảm bảo headers correctly collected
7. **Privacy Compliance**: Verify device ID hashing và location headers consent
8. **Remote Config Testing**: Test enable/disable device headers qua Firebase Remote Config
9. **Header Size Monitoring**: Ensure total header size < 2KB
10. **Network Conditions**: Test header collection under poor network conditions

### Custom Headers Examples

```http
# Example request với full headers:
POST /api/v1/attendance/check-in HTTP/1.1
Host: api.personaai.com
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...

# Device Information
X-Device-Platform: ios
X-Device-Model: iPhone 15 Pro
X-Device-OS-Version: 17.1.1
X-Device-ID: a1b2c3d4e5f6789...
X-Device-Brand: Apple

# Network Information  
X-Network-Type: wifi
X-Network-IP: 192.168.1.100

# App Information
X-App-Version: 1.2.3
X-App-Build: 45
X-App-Environment: production
X-App-Bundle-ID: com.kienlongbank.personaai

# User Context
X-User-Agent: PersonaAI/1.2.3 (iOS 17.1.1; iPhone 15 Pro) Flutter/3.16.0
X-User-Language: vi-VN
X-User-Timezone: Asia/Ho_Chi_Minh

# Session Information
X-Session-ID: 550e8400-e29b-41d4-a716-446655440000
X-Request-ID: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
X-Request-Timestamp: 2024-01-15T10:30:00.000Z
``` 