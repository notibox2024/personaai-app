# Token Refresh Simplification Plan

## 🎯 Mục tiêu
Đơn giản hóa token refresh mechanism bằng cách centralize logic vào `ApiService`, loại bỏ background polling và duplicate code.

## 🔄 Approach mới
**Reactive Token Refresh**: Chỉ refresh token khi API trả về 401 error, không cần background monitoring.

## 📋 Implementation Steps

### Phase 1: Enhanced ApiService (Priority: HIGH)
- [ ] **Fix pending requests handling** trong `_handle401Error()`
  - Implement proper request queuing với original RequestOptions
  - Add retry mechanism sau khi refresh thành công
  - Handle concurrent requests để tránh multiple refresh calls

- [ ] **Add navigation callback** cho login redirect
  - Interface để notify khi cần logout
  - Integration với navigation system

- [ ] **Improve error handling**
  - Prevent infinite loop khi refresh endpoint trả 401
  - Better error messages cho user

### Phase 2: Remove Redundancy (Priority: MEDIUM)  
- [ ] **Delete BackgroundTokenRefreshService**
  - Remove file: `lib/features/auth/data/services/background_token_refresh_service.dart`
  - Update exports trong `auth_exports.dart`
  - Remove references từ `AuthModule`

- [ ] **Simplify AuthService**
  - Remove auto-refresh timer logic (`_startAutoRefreshTimer`, `_stopAutoRefreshTimer`)
  - Remove `_performTokenRefresh()` method
  - Keep only login/logout/validation logic
  - Remove `backgroundRefreshToken()` method

- [ ] **Clean up AppLifecycleService**
  - Remove `BackgroundTokenRefreshService` dependencies
  - Simplify background handling logic

### Phase 3: Testing & Validation (Priority: HIGH)
- [ ] **Test concurrent API calls**
  - Verify chỉ 1 refresh call được thực hiện
  - Test request queuing và retry
  - Validate token expiry scenarios

- [ ] **Integration testing**
  - Test app lifecycle scenarios
  - Verify navigation flow khi token expired
  - Test network connectivity issues

### Phase 4: Cleanup (Priority: LOW)
- [ ] **Remove unused configs**
  - Remove `enableAutoRefresh` từ RemoteConfig nếu không dùng
  - Clean up performance monitoring for background service

- [ ] **Update documentation**
  - Update README với new approach
  - Document API error handling flow

## 🎯 Expected Benefits

### Before
```
AuthService (Timer 30s) ──┐
                          ├─→ TokenManager ──→ Secure Storage
BackgroundService (60s) ──┘
ApiService (401 handler) ──┘
```

### After  
```
ApiService (401 handler) ──→ TokenManager ──→ Secure Storage
```

### Metrics
- **Code reduction**: ~70% less complexity
- **Performance**: Không có background timers
- **Reliability**: Dựa trên actual API behavior
- **Maintainability**: Single responsibility

## ⚠️ Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Multiple refresh calls | Implement `_isRefreshing` flag và request queuing |
| Infinite refresh loop | Check refresh endpoint path trong interceptor |
| Navigation timing | Use callback pattern thay vì direct navigation |
| Testing coverage | Comprehensive concurrent request testing |

## 🚀 Rollout Strategy

1. **Development**: Implement Phase 1 trước
2. **Testing**: Thorough testing với existing features  
3. **Gradual cleanup**: Remove old services từ từ
4. **Monitor**: Track success rates và performance

---
**Timeline**: 2-3 days development + 1 day testing
**Risk Level**: Low (improvements to existing working system) 