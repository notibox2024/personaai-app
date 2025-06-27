# Sử dụng OpenJDK 17 làm base image
FROM openjdk:17-jdk-slim

# Thiết lập thông tin metadata
LABEL maintainer="PersonaAI Team"
LABEL description="PersonaAI Portal Backend API"

# Thiết lập working directory
WORKDIR /app

# Sao chép Gradle wrapper và build files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY gradle.properties .

# Sao chép source code
COPY personnaai-common personnaai-common
COPY personnaai-core personnaai-core
COPY personnaai-api personnaai-api

# Build ứng dụng
RUN chmod +x ./gradlew && \
    ./gradlew :personnaai-api:bootJar --no-daemon

# Tạo user để chạy ứng dụng (bảo mật)
RUN groupadd -r personaai && useradd -r -g personaai personaai

# Sao chép JAR file đã build
RUN cp personnaai-api/build/libs/*.jar app.jar

# Thay đổi ownership cho user personaai
RUN chown -R personaai:personaai /app

# Chuyển sang user personaai
USER personaai

# Expose port 8080
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/personaai-portal/api/health || exit 1

# Chạy ứng dụng
ENTRYPOINT ["java", "-jar", "app.jar"] 