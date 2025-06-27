# PersonaAI Portal Backend

Dự án Spring Boot multi-module cho PersonaAI Portal của Kiên Long Bank.

## Cấu trúc dự án

```
backend/
├── personnaai-common/     # Module chứa các thành phần dùng chung
├── personnaai-core/       # Module chứa nghiệp vụ chính
├── personnaai-api/        # Module REST API (executable)
└── build.gradle           # Cấu hình Gradle chính
```

## Công nghệ sử dụng

- **Spring Boot**: 3.5.3
- **Java**: 17
- **Database**: PostgreSQL 17 (production), H2 (development)
- **Build Tool**: Gradle
- **Documentation**: OpenAPI 3 (Swagger)

## Cài đặt và chạy

### Yêu cầu hệ thống
- Java 17+
- PostgreSQL 17+ (cho production)

### Chạy ứng dụng

1. **Development mode (sử dụng H2 database):**
```bash
cd backend
./gradlew :personnaai-api:bootRun --args='--spring.profiles.active=dev'
```

2. **Production mode (cần MySQL):**
```bash
cd backend
./gradlew :personnaai-api:bootRun
```

### Build project

```bash
cd backend
./gradlew build
```

### Tạo JAR file
```bash
cd backend
./gradlew :personnaai-api:bootJar
```

## API Documentation

Khi ứng dụng chạy, có thể truy cập:
- **Swagger UI**: http://localhost:8080/personaai-portal/swagger-ui.html
- **API Docs**: http://localhost:8080/personaai-portal/v3/api-docs
- **Health Check**: http://localhost:8080/personaai-portal/api/health

## Cấu hình Database

### PostgreSQL (Production)
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/personaai_portal
    username: personaai
    password: password
```

### H2 (Development)
- **Console**: http://localhost:8080/personaai-portal/h2-console
- **JDBC URL**: jdbc:h2:mem:testdb
- **Username**: sa
- **Password**: (để trống)

## Modules

### personnaai-common
Chứa các thành phần dùng chung:
- Base entities và DTOs
- Cấu hình chung
- Utilities

### personnaai-core
Chứa nghiệp vụ chính:
- Business logic
- Services
- Repositories

### personnaai-api
Module REST API:
- Controllers
- API configuration
- Main application class

## Biến môi trường

- `DB_USERNAME`: Tên đăng nhập database (mặc định: personaai)
- `DB_PASSWORD`: Mật khẩu database (mặc định: password)
- `SPRING_PROFILES_ACTIVE`: Profile môi trường (dev/prod)

## Docker Services

Khi chạy với Docker Compose, các service sau sẽ được khởi động:

- **PostgreSQL**: localhost:5432 (username: personaai, password: password)
- **Redis**: localhost:6379
- **PersonaAI API**: localhost:8080 