# Mobile API Schema & PostgREST Integration Guide

## 📋 Tổng quan

Schema `mobile_api` là **PostgREST API layer** chứa các functions được expose qua HTTP để mobile app gọi. Đây là layer trung gian giữa Flutter app và PostgreSQL database, cung cấp **secure, performant API endpoints** với JWT authentication.

### Kiến trúc hệ thống
```
[Flutter App] → [ApiService] → [PostgREST :3300] → [mobile_api functions] → [PostgreSQL Database]
```

## 🗄️ Schema Mobile_API - Chi tiết

### Thống kê
- **Schema**: `mobile_api` ✅ Tồn tại
- **Bảng**: 0 (không lưu trữ dữ liệu)
- **Functions**: 5 PostgreSQL functions (4 existing + 1 new)
- **Port**: 3300 (PostgREST server)
- **Authentication**: JWT-based với Row Level Security

## 🚀 Danh sách Functions

### 1. **get_current_user_profile** ✅ ĐANG SỬ DỤNG
**Endpoint**: `POST /rpc/get_current_user_profile`

**Mục đích**: Lấy profile đầy đủ của user hiện tại

**Return Fields** (30+ fields):
```sql
emp_id, emp_code, first_name, last_name, full_name, email_internal, 
phone, avatar, employee_type, date_join, dob, gender, marital_status, 
education_level, job_title_id, job_title_code, job_title_name, 
job_title_en_name, is_management, organization_id, org_code, org_name, 
org_en_name, parent_org_id, manager_id, manager_name, work_location_id, 
created_at, modified_at
```

**Logic Flow**:
1. Lấy email từ JWT: `current_setting('request.jwt.claims')::json->>'email'`
2. JOIN: `employees + job_titles + organizations + manager`
3. Return: Complete user profile with relationships

**Current Usage**:
- File: `lib/features/auth/data/services/user_profile_service.dart`
- Method: `getCurrentUserProfile()`
- Model: `UserProfile.fromJson()`

### 2. **check_user_permissions** ⏳ CHƯA SỬ DỤNG
**Endpoint**: `POST /rpc/check_user_permissions`

**Mục đích**: Kiểm tra quyền hạn của user hiện tại

**Return Fields**:
```sql
is_manager BOOLEAN, 
organization_id INTEGER, 
job_title_id INTEGER, 
permissions JSONB
```

**Permissions Structure**:
```json
{
  "can_view_team": true,
  "can_manage_team": false, 
  "can_view_org_chart": true
}
```

**Logic Flow**:
1. Lấy email từ JWT
2. Query: `employees + job_titles` 
3. Check: `is_management` flag
4. Return: Permission object

**Potential Usage**:
- **AuthService**: Role-based access control
- **PermissionService**: Feature flagging
- **Home Dashboard**: Conditional UI rendering

### 3. **get_team_members** ⏳ CHƯA SỬ DỤNG
**Endpoint**: `POST /rpc/get_team_members`

**Mục đích**: Lấy danh sách đồng nghiệp cùng phòng ban

**Return Fields**:
```sql
emp_id, emp_code, full_name, email_internal, phone, 
job_title_name, avatar
```

**Logic Flow**:
1. Lấy `organization_id` của user từ JWT
2. Filter: `employees.organization_id = user_org_id`
3. Exclude: `date_resign IS NULL` (chỉ nhân viên đang làm)
4. Return: Danh sách team members

**Potential Usage**:
- **Team Directory Page**: Hiển thị đồng nghiệp
- **Contact List**: Danh bạ nội bộ
- **Org Chart**: Team view
- **Messaging**: Chat với đồng nghiệp

### 4. **get_organization_tree** ⏳ CHƯA SỬ DỤNG
**Endpoint**: `POST /rpc/get_organization_tree`

**Mục đích**: Lấy cây tổ chức từ root đến phòng ban của user

**Return Fields**:
```sql
org_id, org_code, org_name, org_en_name, parent_org_id, level_depth
```

**Logic Flow**:
1. Lấy `organization_id` của user
2. **Recursive CTE**: Build tree từ user org lên root
3. Order: `depth DESC` (từ root xuống)
4. Return: Hierarchical organization structure

**Potential Usage**:
- **Organization Chart**: Hiển thị cây tổ chức
- **Navigation**: Breadcrumb cho departments
- **Reporting**: Hierarchy-based reports
- **Analytics**: Org-level insights

### 5. **update_fcm_token** 🆕 MỚI THÊM
**Endpoint**: `POST /rpc/update_fcm_token`

**Mục đích**: Cập nhật FCM token cho push notifications

**Parameters**:
```sql
fcm_token TEXT
```

**Return Fields**:
```sql
success BOOLEAN, message TEXT, token_id BIGINT, 
employee_id INTEGER, device_id TEXT, platform TEXT
```

**Logic Flow**:
1. Lấy email từ JWT → employee_id từ public.employees
2. Extract device info từ HTTP headers (X-Device-ID, X-Platform, etc.)
3. UPSERT logic: Update existing hoặc insert new token
4. Deactivate duplicate tokens
5. Return: Success status và token info

**Current Usage**:
- **FCM Integration**: Available for immediate implementation
- **Push Notifications**: Ready for notification system
- **Device Tracking**: Automatic device information capture

## 🔐 Security & Authentication

### JWT-based Authentication
Tất cả functions sử dụng:
```sql
current_setting('request.jwt.claims')::json->>'email'
```

### Row Level Security (RLS)
- **Principle**: User chỉ xem được dữ liệu liên quan đến mình
- **Implementation**: Filter theo email/organization_id
- **Benefits**: Data isolation, privacy protection

### Error Handling
```sql
-- Validate JWT
IF user_email IS NULL OR user_email = '' THEN
    RAISE EXCEPTION 'Email không tồn tại trong JWT token';
END IF;

-- Validate user exists  
IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy thông tin nhân viên với email: %', user_email;
END IF;
```

## 🔧 Technical Implementation

### API Service Integration

#### Current Implementation
```dart
// lib/features/auth/data/services/user_profile_service.dart
class UserProfileService {
  static const String _getCurrentUserProfileEndpoint = '/rpc/get_current_user_profile';
  
  Future<UserProfile> getCurrentUserProfile() async {
    // Switch to PostgREST mode
    await _apiService.switchToDataApi();
    
    // Call RPC with JWT auto-attached
    final response = await _apiService.post(_getCurrentUserProfileEndpoint);
    
    // Parse response array
    if (response.data is List && (response.data as List).isNotEmpty) {
      final userData = (response.data as List).first;
      return UserProfile.fromJson(userData);
    }
  }
}
```

#### ApiService PostgREST Mode
```dart
// lib/shared/services/api_service.dart
Future<void> switchToDataApi() async {
  String dataUrl = ApiEndpoints.getDataUrl(); // http://192.168.2.62:3300
  _dio.options.baseUrl = dataUrl;
  _currentMode = 'data';
  
  // JWT token automatically added by interceptor
}
```

### Request Flow
1. **App Call**: `userProfileService.getCurrentUserProfile()`
2. **API Switch**: `switchToDataApi()` → baseUrl = `:3300`
3. **HTTP Request**: `POST /rpc/get_current_user_profile`
4. **JWT Interceptor**: Add `Authorization: Bearer <token>`
5. **PostgREST**: Parse JWT → call function với user context
6. **PostgreSQL**: Execute function với RLS
7. **Response**: JSON array với user data
8. **Parsing**: `UserProfile.fromJson()`

## 📊 Usage Status & Opportunities

### ✅ Currently Used (1/5)
- `get_current_user_profile` → `UserProfileService`

### 🆕 New Function Available (1/5)
- `update_fcm_token` → Ready for `FcmTokenService` implementation

### ⏳ Ready to Implement (3/5)

#### 1. Permission Management
```dart
// lib/features/auth/data/services/permission_service.dart
class PermissionService {
  Future<UserPermissions> checkUserPermissions() async {
    await _apiService.switchToDataApi();
    final response = await _apiService.post('/rpc/check_user_permissions');
    return UserPermissions.fromJson(response.data.first);
  }
}

// Usage in UI
if (await permissionService.canManageTeam()) {
  // Show manager features
}
```

#### 2. Team Directory Feature  
```dart
// lib/features/team/data/services/team_service.dart
class TeamService {
  Future<List<TeamMember>> getTeamMembers() async {
    await _apiService.switchToDataApi();
    final response = await _apiService.post('/rpc/get_team_members');
    return (response.data as List)
        .map((json) => TeamMember.fromJson(json))
        .toList();
  }
}
```

#### 3. Organization Chart
```dart
// lib/features/organization/data/services/org_service.dart
class OrganizationService {
  Future<List<OrgNode>> getOrganizationTree() async {
    await _apiService.switchToDataApi();
    final response = await _apiService.post('/rpc/get_organization_tree');
    return (response.data as List)
        .map((json) => OrgNode.fromJson(json))
        .toList();
  }
}
```

## 🎯 Implementation Roadmap

### Phase 1: Foundation (Complete ✅)
- [x] PostgREST integration
- [x] JWT authentication flow
- [x] User profile service
- [x] Error handling & retry logic

### Phase 1.5: Push Notifications (New 🆕)
- [x] FCM token update function created
- [ ] Implement `FcmTokenService` in Flutter
- [ ] Integrate into auth flow
- [ ] Setup token refresh listeners
- [ ] Test end-to-end push notifications

### Phase 2: User Management
- [ ] Implement `check_user_permissions`
- [ ] Role-based UI rendering
- [ ] Permission caching strategy
- [ ] Admin user detection

### Phase 3: Team Features
- [ ] Implement `get_team_members`
- [ ] Team directory page
- [ ] Contact search & filter
- [ ] Team member profiles

### Phase 4: Organization Features
- [ ] Implement `get_organization_tree`
- [ ] Interactive org chart
- [ ] Department navigation
- [ ] Hierarchy-based features

## 🚨 Best Practices & Considerations

### Performance
- **Caching**: Consider caching team/org data (refresh strategies)
- **Pagination**: Large teams may need pagination
- **Lazy Loading**: Load org tree incrementally

### Security
- **Token Refresh**: Handle 401 with automatic retry
- **Data Validation**: Server-side validation trong functions
- **Rate Limiting**: PostgREST rate limiting cho production

### Error Handling
```dart
try {
  await _apiService.switchToDataApi();
  final response = await _apiService.post('/rpc/function_name');
  return parseResponse(response);
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // JWT expired - will auto-refresh
    throw AuthenticationException();
  }
  throw DataApiException(e.message);
}
```

### Testing Strategy
```dart
// Mock PostgREST responses for unit tests
when(mockApiService.post('/rpc/get_current_user_profile'))
    .thenAnswer((_) async => Response(
      data: [mockUserProfileJson],
      statusCode: 200,
    ));
```

## 🔍 Debug & Troubleshooting

### Common Issues
1. **JWT Claims Empty**: Check token format và parsing
2. **Function Not Found**: Verify PostgREST schema exposure
3. **Permission Denied**: Check RLS policies
4. **Connection Failed**: Verify PostgREST server status

### Debug Commands
```sql
-- Test function directly
SELECT * FROM mobile_api.get_current_user_profile();

-- Check JWT claims
SELECT current_setting('request.jwt.claims');

-- Verify user exists
SELECT email_internal FROM employees WHERE email_internal = 'user@company.com';
```

### Monitoring
- **PostgREST Logs**: Monitor function execution
- **API Metrics**: Track response times & error rates  
- **JWT Validity**: Monitor token refresh patterns

---

## 📝 Schema SQL Reference

Để xem chi tiết implementation của functions:
```sql
-- List all functions
\df mobile_api.*

-- View function definition
\sf mobile_api.get_current_user_profile
\sf mobile_api.check_user_permissions
\sf mobile_api.get_team_members  
\sf mobile_api.get_organization_tree
```

---
*Tài liệu này cung cấp đầy đủ context về mobile_api schema và PostgREST integration để implement các features mới.* 