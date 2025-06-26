# API Service với Dio

Hướng dẫn sử dụng API Service trong dự án PersonaAI sử dụng package Dio.

## Cài đặt

Package Dio đã được thêm vào `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.8.0+1
```

## Khởi tạo

API Service được khởi tạo trong `main.dart`:

```dart
void main() {
  // Khởi tạo API service
  ApiService().initialize(
    baseUrl: 'https://api.personaai.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 5),
  );
  
  runApp(const MyApp());
}
```

## Sử dụng cơ bản

### 1. GET Request

```dart
final apiService = ApiService();

try {
  final response = await apiService.get('/users/profile');
  final user = User.fromJson(response.data);
} on ApiException catch (e) {
  print('API Error: ${e.message}');
} catch (e) {
  print('Unknown Error: $e');
}
```

### 2. POST Request

```dart
try {
  final response = await apiService.post(
    '/users/create',
    data: {
      'name': 'Nguyễn Văn A',
      'email': 'nguyenvana@example.com',
    },
  );
} on ApiException catch (e) {
  print('API Error: ${e.message}');
}
```

### 3. PUT Request

```dart
try {
  await apiService.put(
    '/users/123',
    data: {'name': 'Tên mới'},
  );
} on ApiException catch (e) {
  print('API Error: ${e.message}');
}
```

### 4. DELETE Request

```dart
try {
  await apiService.delete('/users/123');
} on ApiException catch (e) {
  print('API Error: ${e.message}');
}
```

## Tính năng nâng cao

### 1. Authentication

Thêm token xác thực:

```dart
final apiService = ApiService();
apiService.setAuthToken('your-jwt-token');

// Xóa token khi logout
apiService.clearAuthToken();
```

### 2. Upload File

```dart
try {
  final response = await apiService.uploadFile(
    '/upload/avatar',
    '/path/to/image.jpg',
    filename: 'avatar.jpg',
    data: {'userId': '123'},
    onSendProgress: (sent, total) {
      print('Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
    },
  );
} on ApiException catch (e) {
  print('Upload Error: ${e.message}');
}
```

### 3. Download File

```dart
try {
  await apiService.downloadFile(
    '/files/document.pdf',
    '/local/path/document.pdf',
    onReceiveProgress: (received, total) {
      print('Download: ${(received / total * 100).toStringAsFixed(0)}%');
    },
  );
} on ApiException catch (e) {
  print('Download Error: ${e.message}');
}
```

### 4. Query Parameters

```dart
final response = await apiService.get(
  '/users',
  queryParameters: {
    'page': 1,
    'limit': 20,
    'search': 'keyword',
  },
);
```

### 5. Custom Headers

```dart
final response = await apiService.get(
  '/protected-endpoint',
  options: Options(
    headers: {
      'Custom-Header': 'value',
      'Another-Header': 'another-value',
    },
  ),
);
```

## Repository Pattern

Sử dụng Repository pattern để tổ chức code:

```dart
class UserRepository {
  final ApiService _apiService = ApiService();

  Future<User> getUserProfile() async {
    try {
      final response = await _apiService.get('/user/profile');
      return User.fromJson(response.data);
    } on ApiException catch (e) {
      throw Exception('Không thể lấy thông tin người dùng: ${e.message}');
    }
  }

  Future<void> updateProfile(User user) async {
    try {
      await _apiService.put(
        '/user/profile',
        data: user.toJson(),
      );
    } on ApiException catch (e) {
      throw Exception('Không thể cập nhật thông tin: ${e.message}');
    }
  }
}
```

## Xử lý lỗi

API Service cung cấp các loại lỗi sau:

```dart
enum ApiExceptionType {
  connectionTimeout,    // Timeout kết nối
  sendTimeout,         // Timeout gửi dữ liệu
  receiveTimeout,      // Timeout nhận dữ liệu
  serverError,         // Lỗi từ server (4xx, 5xx)
  cancelled,           // Request bị hủy
  noConnection,        // Không có kết nối internet
  unknown,             // Lỗi không xác định
}
```

Xử lý lỗi cụ thể:

```dart
try {
  final response = await apiService.get('/data');
} on ApiException catch (e) {
  switch (e.type) {
    case ApiExceptionType.noConnection:
      showMessage('Không có kết nối internet');
      break;
    case ApiExceptionType.serverError:
      if (e.statusCode == 401) {
        // Redirect to login
      } else if (e.statusCode == 403) {
        showMessage('Không có quyền truy cập');
      }
      break;
    case ApiExceptionType.connectionTimeout:
      showMessage('Kết nối bị timeout');
      break;
    default:
      showMessage('Có lỗi xảy ra: ${e.message}');
  }
}
```

## Hủy Request

```dart
final apiService = ApiService();

// Hủy tất cả requests
apiService.cancelRequests('User cancelled');

// Hoặc sử dụng CancelToken riêng
final cancelToken = CancelToken();
apiService.get('/data', cancelToken: cancelToken);

// Hủy request cụ thể
cancelToken.cancel('Cancelled by user');
```

## Debug & Logging

Trong debug mode, API Service sẽ tự động log:
- Request details (URL, headers, data)
- Response details (status, data)
- Error details (type, message, status code)

Logs sẽ hiển thị với format dễ đọc:
- 🚀 REQUEST: GET https://api.example.com/users
- ✅ RESPONSE: 200 https://api.example.com/users
- ❌ ERROR: Connection timeout

## Best Practices

1. **Sử dụng Repository Pattern**: Tách biệt logic API khỏi UI
2. **Xử lý lỗi đầy đủ**: Luôn handle ApiException
3. **Sử dụng Models**: Parse JSON thành objects với fromJson/toJson
4. **Timeout hợp lý**: Đặt timeout phù hợp với từng loại request
5. **Cancel requests**: Hủy requests khi không cần thiết (user navigate away)
6. **Loading states**: Hiển thị loading indicator khi gọi API
7. **Retry mechanism**: Implement retry cho các request quan trọng

## Ví dụ hoàn chỉnh

Xem file `lib/features/home/data/repositories/home_repository.dart` để có ví dụ đầy đủ về cách sử dụng API Service trong thực tế.

# Location Service - Hướng dẫn sử dụng

## Mục đích
LocationService cung cấp các chức năng xử lý vị trí và quyền truy cập location cho ứng dụng HR PersonaAI, đặc biệt cho chức năng chấm công.

## Cài đặt đã hoàn thành

### 1. Permissions đã được thêm

#### Android (AndroidManifest.xml)
```xml
<!-- Quyền truy cập vị trí cho chức năng chấm công -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Quyền truy cập vị trí ở background (Android 10+) -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Quyền internet để gọi API -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Quyền kiểm tra trạng thái mạng -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### iOS (Info.plist)
```xml
<!-- Quyền truy cập vị trí khi sử dụng app -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền truy cập vị trí để xác định vị trí chấm công và đảm bảo nhân viên đang ở đúng địa điểm làm việc.</string>

<!-- Quyền truy cập vị trí luôn luôn (iOS 11+) -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền truy cập vị trí để thực hiện chấm công tự động và theo dõi thời gian làm việc tại địa điểm công ty.</string>

<!-- Quyền truy cập vị trí chính xác (iOS 14+) -->
<key>NSLocationTemporaryUsageDescriptionDictionary</key>
<dict>
    <key>attendanceTracking</key>
    <string>Cần vị trí chính xác để xác minh bạn đang ở địa điểm làm việc khi chấm công.</string>
</dict>
```

### 2. Dependencies đã được thêm (pubspec.yaml)
```yaml
dependencies:
  # Location services
  location: ^5.0.3
  
  # Permission handler
  permission_handler: ^11.3.1
  
  # Geolocator for location services
  geolocator: ^10.1.1
```

## Cách sử dụng

### 1. Import
```dart
import 'package:geolocator/geolocator.dart';
import '../../../../shared/shared_exports.dart';
```

### 2. Kiểm tra và yêu cầu quyền
```dart
// Kiểm tra trạng thái quyền
final status = await LocationService.getLocationPermissionStatus();

// Yêu cầu quyền nếu cần
bool granted = await LocationService.requestLocationPermission();

// Hiển thị dialog yêu cầu quyền
await LocationPermissionDialog.show(
  context,
  onPermissionGranted: () {
    // Quyền được cấp
  },
  onPermissionDenied: () {
    // Quyền bị từ chối
  },
);
```

### 3. Lấy vị trí hiện tại
```dart
Position? position = await LocationService.getCurrentLocation();

if (position != null) {
  print('Lat: ${position.latitude}, Lng: ${position.longitude}');
  print('Accuracy: ${position.accuracy} meters');
}
```

### 4. Kiểm tra vị trí có trong phạm vi không
```dart
// Định nghĩa workplace location
const workplace = WorkplaceLocation(
  id: 'main_office',
  name: 'Văn phòng chính',
  latitude: 10.762622,
  longitude: 106.660172,
  radiusInMeters: 100.0,
  address: '123 Đường ABC, Quận 1, TP.HCM',
);

// Kiểm tra vị trí hiện tại có trong phạm vi không
bool isWithinRange = LocationService.isWithinAllowedRange(
  position,
  workplace.latitude,
  workplace.longitude,
  radiusInMeters: workplace.radiusInMeters,
);

// Tính khoảng cách
double distance = LocationService.calculateDistanceToWorkplace(
  position,
  workplace.latitude,
  workplace.longitude,
);
```

### 5. Xử lý các trường hợp lỗi
```dart
switch (status) {
  case LocationPermissionStatus.denied:
    // Hiển thị dialog yêu cầu quyền
    break;
    
  case LocationPermissionStatus.deniedForever:
    // Hướng dẫn user mở Settings
    await LocationService.openAppSettings();
    break;
    
  case LocationPermissionStatus.serviceDisabled:
    // Hướng dẫn user bật Location Service
    await LocationService.openLocationSettings();
    break;
    
  case LocationPermissionStatus.whileInUse:
  case LocationPermissionStatus.always:
    // Có quyền, tiến hành lấy location
    break;
}
```

## Models đã định nghĩa

### WorkplaceLocation
```dart
const workplace = WorkplaceLocation(
  id: 'office_001',
  name: 'Văn phòng chính',
  latitude: 10.762622,
  longitude: 106.660172,
  radiusInMeters: 100.0,
  address: '123 Đường ABC, Quận 1, TP.HCM',
);
```

### CheckInLocation
```dart
// Tạo từ Position
final checkInLocation = CheckInLocation.fromPosition(
  position,
  'Địa chỉ văn phong', // address
);

// Chuyển thành JSON để lưu API
Map<String, dynamic> json = checkInLocation.toJson();
```

## Dialogs đã tạo

1. **LocationPermissionDialog**: Dialog yêu cầu quyền location
2. **LocationPermissionDeniedDialog**: Dialog khi quyền bị từ chối
3. **LocationServiceDisabledDialog**: Dialog khi location service bị tắt

## Lưu ý quan trọng

1. **Luôn kiểm tra quyền trước khi sử dụng location**
2. **Xử lý các trường hợp lỗi appropriately**
3. **Sử dụng timeout cho getCurrentLocation() để tránh block UI**
4. **Kiểm tra độ chính xác (accuracy) của vị trí**
5. **Sử dụng background location permission cẩn thận (có thể bị reject từ app store)**

## Testing

Để test trên simulator/emulator:
1. iOS Simulator: Features > Location > Custom Location
2. Android Emulator: Extended controls > Location

## Troubleshooting

### Lỗi thường gặp:
1. **Permission denied**: Đảm bảo đã thêm permissions vào manifest files
2. **Location service disabled**: User cần bật GPS/Location Service
3. **Timeout**: Increase timeout hoặc decrease accuracy requirement
4. **Low accuracy**: Yêu cầu user di chuyển ra ngoài trời hoặc gần cửa sổ

### Debug:
```dart
// Check permission status
final status = await LocationService.getLocationPermissionStatus();
print('Permission status: $status');

// Check service enabled
bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
print('Service enabled: $serviceEnabled');
``` 