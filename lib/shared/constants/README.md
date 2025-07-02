# API Endpoints Configuration

Hệ thống quản lý URL API cho các environment khác nhau trong dự án PersonaAI.

## Tổng quan

Dự án hỗ trợ 2 chế độ chính:
- **Development Mode**: Sử dụng URL constants trong code
- **Production Mode**: Sử dụng Remote Config từ Firebase

## Cách sử dụng

### Development Mode

Trong chế độ development (`kDebugMode` hoặc `kProfileMode`), hệ thống sẽ sử dụng các URL được định nghĩa trong `ApiEndpoints`.

#### Thay đổi Environment

Để thay đổi environment trong development, sửa `currentEnvironment` trong file `api_endpoints.dart`:

```dart
// Thay đổi dòng này
static const ApiEnvironment currentEnvironment = ApiEnvironment.development;
```

#### Các Environment có sẵn:

1. **Development** (mặc định)
   ```
   Backend: http://192.168.2.62:8097
   Data: http://192.168.2.62:3300
   ```

2. **Local**
   ```
   Backend: http://localhost:8097
   Data: http://localhost:3300
   ```

3. **Staging**
   ```
   Backend: https://api-staging.example.com
   Data: https://data-staging.example.com
   ```

4. **Custom**
   ```
   Backend: http://192.168.1.100:8097
   Data: http://192.168.1.100:3300
   ```

#### Tùy chỉnh URL

Để sử dụng URL riêng của bạn:

1. **Option 1**: Cập nhật URL trong environment hiện tại
   ```dart
   // Trong api_endpoints.dart
   static const String devBackendApiUrl = 'http://YOUR_IP:8097';
   static const String devDataApiUrl = 'http://YOUR_IP:3300';
   ```

2. **Option 2**: Sử dụng Custom environment
   ```dart
   // Cập nhật custom URLs
   static const String customBackendApiUrl = 'http://YOUR_IP:8097';
   static const String customDataApiUrl = 'http://YOUR_IP:3300';
   
   // Thay đổi environment
   static const ApiEnvironment currentEnvironment = ApiEnvironment.custom;
   ```

3. **Option 3**: Tạo environment mới
   ```dart
   // Thêm vào enum
   enum ApiEnvironment {
     development,
     local,
     staging,
     custom,
     myEnvironment, // <- thêm mới
     production,
   }
   
   // Thêm constants
   static const String myBackendApiUrl = 'http://my-server:8097';
   static const String myDataApiUrl = 'http://my-server:3300';
   
   // Thêm case trong switch statements
   case ApiEnvironment.myEnvironment:
     return myBackendApiUrl; // hoặc myDataApiUrl
   ```

### Production Mode

Trong production build (`kReleaseMode`), hệ thống sẽ luôn sử dụng Remote Config từ Firebase.

URL sẽ được lấy từ:
- `backend_api_url` cho Backend API
- `data_api_url` cho Data API

## Debug Information

Khi chạy ở development mode, ApiService sẽ log thông tin environment:

```
ApiService initialized with base URL: http://192.168.2.62:8097 (from development)
Default API mode set to: backend
Current environment URLs:
  Backend: http://192.168.2.62:8097
  Data: http://192.168.2.62:3300
  Environment: development
To change URLs, update ApiEndpoints.currentEnvironment
```

## Helper Methods

### Hiển thị thông tin environments

```dart
// Trong code development
ApiEndpoints.printAvailableEnvironments();
```

### Lấy thông tin hiện tại

```dart
// Check environment
bool isDev = ApiEndpoints.isDevelopmentMode;
bool isProd = ApiEndpoints.isProductionMode;
String envName = ApiEndpoints.currentEnvironmentName;

// Lấy URLs
Map<String, String> urls = ApiEndpoints.getCurrentUrls();
print('Backend: ${urls['backend']}');
print('Data: ${urls['data']}');
```

## Best Practices

1. **Không hardcode URL** trong business logic
2. **Sử dụng ApiService** để gọi API, không gọi trực tiếp
3. **Test với nhiều environment** trước khi push code
4. **Không commit** URL production vào constants
5. **Sử dụng Remote Config** cho production settings

## Troubleshooting

### Lỗi "Production build must use remote config"

- Nguyên nhân: Cố gắng sử dụng constants trong production build
- Giải pháp: Đảm bảo Remote Config được setup đúng

### URL không đúng trong development

- Kiểm tra `currentEnvironment` trong `api_endpoints.dart`
- Kiểm tra URL constants cho environment hiện tại
- Restart app sau khi thay đổi

### API call bị lỗi

- Kiểm tra server có chạy không
- Kiểm tra network connectivity
- Xem log để biết URL nào đang được sử dụng

## Migration từ hệ thống cũ

Nếu bạn đang sử dụng hardcode URL trong code:

```dart
// CŨ - không nên
final response = await dio.get('http://192.168.2.62:8097/api/users');

// MỚI - nên sử dụng
final apiService = ApiService();
await apiService.switchToBackendApi(); // nếu cần
final response = await apiService.get('/api/users');
``` 