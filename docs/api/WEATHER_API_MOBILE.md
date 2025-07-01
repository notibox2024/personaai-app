# Weather API - Mobile Development Guide

## Tổng quan

API Weather Service tích hợp với Open-Meteo API để cung cấp thông tin thời tiết theo tọa độ địa lý. Hỗ trợ các tùy chọn đơn vị đo lường khác nhau.

**Base URL:** `/api/v1/weather`

## Endpoints

### 1. Lấy thời tiết hiện tại (Chi tiết)

**POST** `/api/v1/weather/current`

Lấy thông tin thời tiết với đầy đủ tùy chọn cấu hình.

**Authentication:** Required (Bearer token)

**Request Model:** `WeatherRequest`
```json
{
  "latitude": 21.0285,
  "longitude": 105.8542,
  "currentWeather": true,
  "timezone": "auto",
  "temperatureUnit": "celsius",
  "windspeedUnit": "kmh", 
  "precipitationUnit": "mm"
}
```

**Response Model:** `WeatherResponse`
```json
{
  "latitude": 21.0,
  "longitude": 105.875,
  "generationtime_ms": 0.123,
  "utc_offset_seconds": 25200,
  "timezone": "Asia/Ho_Chi_Minh",
  "timezone_abbreviation": "+07",
  "elevation": 6.0,
  "current_weather_units": {
    "time": "iso8601",
    "interval": "seconds",
    "temperature": "°C",
    "windspeed": "km/h",
    "winddirection": "°",
    "is_day": "",
    "weathercode": "wmo code"
  },
  "current_weather": {
    "time": "2024-01-15T10:30",
    "interval": 900,
    "temperature": 25.2,
    "windspeed": 8.5,
    "winddirection": 180,
    "is_day": 1,
    "weathercode": 3
  }
}
```

### 2. Lấy thời tiết hiện tại (Đơn giản)

**GET** `/api/v1/weather/current`

Lấy thông tin thời tiết với cấu hình mặc định.

**Authentication:** Required (Bearer token)

**Parameters:**
- `latitude` (required): Vĩ độ (-90 đến 90)
- `longitude` (required): Kinh độ (-180 đến 180)

**Example:**
```
GET /api/v1/weather/current?latitude=21.0285&longitude=105.8542
```

**Response Model:** `WeatherResponse` (giống như POST)

### 3. Thời tiết Hà Nội (Test)

**GET** `/api/v1/weather/hanoi`

Lấy thông tin thời tiết Hà Nội để test.

**Authentication:** Not required

**Response Model:** `WeatherResponse`

### 4. Thời tiết Berlin (Test)

**GET** `/api/v1/weather/berlin`

Lấy thông tin thời tiết Berlin để test.

**Authentication:** Not required

**Response Model:** `WeatherResponse`

## Request Model Details

### WeatherRequest Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| latitude | Double | Yes | - | Vĩ độ (-90 đến 90) |
| longitude | Double | Yes | - | Kinh độ (-180 đến 180) |
| currentWeather | Boolean | No | true | Lấy thông tin thời tiết hiện tại |
| timezone | String | No | "auto" | Múi giờ (auto/UTC/specific) |
| temperatureUnit | String | No | "celsius" | celsius, fahrenheit |
| windspeedUnit | String | No | "kmh" | kmh, ms, mph, kn |
| precipitationUnit | String | No | "mm" | mm, inch |

## Response Model Details

### CurrentWeather Fields

| Field | Type | Description |
|-------|------|-------------|
| time | String | Thời gian đo (ISO8601) |
| interval | Integer | Khoảng thời gian đo (giây) |
| temperature | Double | Nhiệt độ |
| windspeed | Double | Tốc độ gió |
| winddirection | Integer | Hướng gió (độ) |
| is_day | Integer | Ngày (1) hay đêm (0) |
| weathercode | Integer | Mã thời tiết WMO |

### Weather Codes (WMO)

| Code | Description |
|------|-------------|
| 0 | Trời quang đãng |
| 1-3 | Có mây ít/vừa/nhiều |
| 45,48 | Có sương mù |
| 51-57 | Mưa phùn |
| 61-67 | Mưa |
| 71-77 | Tuyết |
| 80-82 | Mưa rào |
| 95-99 | Dông bão |

## Authentication

Các endpoint yêu cầu authentication:
- POST `/current`
- GET `/current`

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

## Error Handling

| HTTP Code | Description |
|-----------|-------------|
| 400 | Tọa độ không hợp lệ |
| 401 | Token không hợp lệ |
| 403 | Không có quyền truy cập |
| 500 | Lỗi service thời tiết |

## Usage Examples

### Mobile App Flow
1. Lấy tọa độ hiện tại từ GPS
2. Gọi API với coordinates
3. Hiển thị thông tin thời tiết
4. Cache data để giảm API calls

### Coordinates Examples
- **Hà Nội:** lat=21.0285, lon=105.8542
- **TP.HCM:** lat=10.8231, lon=106.6297  
- **Đà Nẵng:** lat=16.0471, lon=108.2068

## Model Classes

- **Request Model:** `WeatherRequest`
- **Response Model:** `WeatherResponse`, `CurrentWeather`, `CurrentWeatherUnits`
- **Package:** `com.kienlongbank.personaai.portal.core.data.models.weather`

## Notes cho Mobile Dev

1. **Caching:** Cache weather data 15-30 phút để giảm API calls
2. **Location:** Xin permission location trước khi gọi API
3. **Offline:** Store last weather data cho offline mode  
4. **Units:** Cho phép user chọn đơn vị đo lường
5. **Icons:** Map weathercode với weather icons
6. **Retry:** Implement retry logic cho network errors 