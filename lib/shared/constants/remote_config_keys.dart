/// Các hằng số cho Remote Config Keys
/// 
/// Class này chứa tất cả các key được sử dụng trong Firebase Remote Config
/// được nhóm theo chức năng để dễ quản lý và sử dụng
class RemoteConfigKeys {
  // Private constructor để ngăn khởi tạo
  const RemoteConfigKeys._();

  // ============== APP CONFIGURATION ==============
  
  /// Phiên bản ứng dụng yêu cầu tối thiểu
  static const String appVersionRequired = 'app_version_required';
  
  /// Chế độ bảo trì
  static const String maintenanceMode = 'maintenance_mode';
  
  /// Thông báo bảo trì
  static const String maintenanceMessage = 'maintenance_message';

  // ============== FEATURE FLAGS ==============
  
  /// Bật/tắt đăng nhập bằng sinh trắc học
  static const String enableBiometricLogin = 'enable_biometric_login';
  
  /// Bật/tắt chế độ offline
  static const String enableOfflineMode = 'enable_offline_mode';
  
  /// Bật/tắt giao diện tối
  static const String enableDarkTheme = 'enable_dark_theme';
  
  /// Bật/tắt thông báo đẩy
  static const String enablePushNotifications = 'enable_push_notifications';
  
  /// Bật/tắt theo dõi vị trí
  static const String enableLocationTracking = 'enable_location_tracking';

  // ============== DEVICE HEADERS CONFIGURATION ==============
  
  /// Bật/tắt device headers
  static const String enableDeviceHeaders = 'enable_device_headers';
  
  /// Bật/tắt network headers
  static const String enableNetworkHeaders = 'enable_network_headers';
  
  /// Bật/tắt location headers
  static const String enableLocationHeaders = 'enable_location_headers';
  
  /// Bật/tắt IP tracking
  static const String enableIpTracking = 'enable_ip_tracking';

  // ============== AUTHENTICATION CONFIGURATION ==============
  
  /// Bật/tắt auto refresh token
  static const String enableAutoRefresh = 'enable_auto_refresh';
  
  /// Ngưỡng refresh token (phút)
  static const String refreshThresholdMinutes = 'refresh_threshold_minutes';

  // ============== UI CONFIGURATION ==============
  
  /// Khoảng cách tối đa để chấm công (mét)
  static const String maxAttendanceDistance = 'max_attendance_distance';
  
  /// Số giờ tự động checkout
  static const String autoCheckOutHours = 'auto_check_out_hours';
  
  /// Thời gian nghỉ trưa (phút)
  static const String breakTimeMinutes = 'break_time_minutes';

  // ============== API CONFIGURATION ==============
  
  /// Timeout của API (giây)
  static const String apiTimeoutSeconds = 'api_timeout_seconds';
  
  /// Số lần thử lại tối đa
  static const String maxRetryAttempts = 'max_retry_attempts';
  
  /// Thời gian cache (giờ)
  static const String cacheDurationHours = 'cache_duration_hours';
  
  /// URL API backend (Spring Boot)
  static const String backendApiUrl = 'backend_api_url';
  
  /// URL API dữ liệu (postgREST)
  static const String dataApiUrl = 'data_api_url';

  // ============== NOTIFICATION CONFIGURATION ==============
  
  /// Giờ bắt đầu chế độ im lặng thông báo
  static const String notificationQuietHoursStart = 'notification_quiet_hours_start';
  
  /// Giờ kết thúc chế độ im lặng thông báo
  static const String notificationQuietHoursEnd = 'notification_quiet_hours_end';
  
  /// Số thông báo tối đa mỗi ngày
  static const String maxDailyNotifications = 'max_daily_notifications';

  // ============== TRAINING CONFIGURATION ==============
  
  /// Thời lượng buổi đào tạo (phút)
  static const String trainingSessionDuration = 'training_session_duration';
  
  /// Bật/tắt nhắc nhở đào tạo
  static const String enableTrainingReminders = 'enable_training_reminders';
  
  /// Khoảng thời gian đồng bộ tiến độ đào tạo (giây)
  static const String trainingProgressSyncInterval = 'training_progress_sync_interval';

  // ============== DEFAULTS ==============
  
  /// Giá trị mặc định cho các config
  static const Map<String, dynamic> defaultValues = {
    // App configuration
    appVersionRequired: '1.0.0',
    maintenanceMode: false,
    maintenanceMessage: 'Ứng dụng đang được bảo trì. Vui lòng thử lại sau.',
    
    // Feature flags
    enableBiometricLogin: true,
    enableOfflineMode: false,
    enableDarkTheme: true,
    enablePushNotifications: true,
    enableLocationTracking: true,
    
    // Device headers
    enableDeviceHeaders: true,
    enableNetworkHeaders: true,
    enableLocationHeaders: false,
    enableIpTracking: false,
    
    // Authentication
    enableAutoRefresh: true,
    refreshThresholdMinutes: 2,
    
    // UI configuration
    maxAttendanceDistance: 100, // meters
    autoCheckOutHours: 8,
    breakTimeMinutes: 60,
    
    // API configuration
    apiTimeoutSeconds: 30,
    maxRetryAttempts: 3,
    cacheDurationHours: 24,
    backendApiUrl: 'http://192.168.2.62:8097',
    dataApiUrl: 'http://192.168.2.62:3300',
    
    // Notification settings
    notificationQuietHoursStart: 22,
    notificationQuietHoursEnd: 6,
    maxDailyNotifications: 10,
    
    // Training configuration
    trainingSessionDuration: 30, // minutes
    enableTrainingReminders: true,
    trainingProgressSyncInterval: 300, // seconds
  };

  // ============== UTILITY METHODS ==============
  
  /// Lấy tất cả các key
  static List<String> getAllKeys() {
    return [
      // App configuration
      appVersionRequired,
      maintenanceMode,
      maintenanceMessage,
      
      // Feature flags
      enableBiometricLogin,
      enableOfflineMode,
      enableDarkTheme,
      enablePushNotifications,
      enableLocationTracking,
      
      // UI configuration
      maxAttendanceDistance,
      autoCheckOutHours,
      breakTimeMinutes,
      
      // API configuration
      apiTimeoutSeconds,
      maxRetryAttempts,
      cacheDurationHours,
      backendApiUrl,
      dataApiUrl,
      
      // Notification configuration
      notificationQuietHoursStart,
      notificationQuietHoursEnd,
      maxDailyNotifications,
      
      // Training configuration
      trainingSessionDuration,
      enableTrainingReminders,
      trainingProgressSyncInterval,
    ];
  }
  
  /// Lấy các key theo nhóm chức năng
  static List<String> getAppConfigKeys() {
    return [
      appVersionRequired,
      maintenanceMode,
      maintenanceMessage,
    ];
  }
  
  static List<String> getFeatureFlagKeys() {
    return [
      enableBiometricLogin,
      enableOfflineMode,
      enableDarkTheme,
      enablePushNotifications,
      enableLocationTracking,
    ];
  }
  
  static List<String> getUiConfigKeys() {
    return [
      maxAttendanceDistance,
      autoCheckOutHours,
      breakTimeMinutes,
    ];
  }
  
  static List<String> getApiConfigKeys() {
    return [
      apiTimeoutSeconds,
      maxRetryAttempts,
      cacheDurationHours,
      backendApiUrl,
      dataApiUrl,
    ];
  }
  
  static List<String> getNotificationConfigKeys() {
    return [
      notificationQuietHoursStart,
      notificationQuietHoursEnd,
      maxDailyNotifications,
    ];
  }
  
  static List<String> getTrainingConfigKeys() {
    return [
      trainingSessionDuration,
      enableTrainingReminders,
      trainingProgressSyncInterval,
    ];
  }
} 