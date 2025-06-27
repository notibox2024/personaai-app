# Git Ignore Configuration

## Files và folders được ignore:

### 🏗️ **Build artifacts**
- `.gradle/` - Gradle cache và temporary files
- `build/` - Build output directories
- `*.jar`, `*.war`, `*.ear` - Compiled Java archives (trừ gradle-wrapper.jar)
- `out/`, `bin/` - IDE output directories

### 💾 **IDE files**
- `.idea/` - IntelliJ IDEA configuration
- `*.iml`, `*.ipr`, `*.iws` - IntelliJ module files
- `.vscode/` - VS Code settings
- `.settings/`, `.project`, `.classpath` - Eclipse configuration

### 📊 **Logs và reports**
- `*.log` - Log files
- `logs/` - Log directories
- `test-results/`, `reports/` - Test và coverage reports

### 🗄️ **Database files**
- `*.db`, `*.sqlite`, `*.sqlite3` - SQLite databases
- `*.h2.db`, `*.trace.db`, `*.lock.db` - H2 database files

### 🔐 **Security files**
- `*.jks`, `*.keystore`, `*.p12` - Java keystores
- `.env*` - Environment variables files
- `local.properties`, `local.yml` - Local configuration

### 🐳 **Docker**
- `docker-compose.override.yml` - Local Docker overrides

### 🗃️ **Temporary files**
- `*.tmp`, `*.temp`, `*~`, `*.bak`, `*.swp` - Temporary/backup files
- `.DS_Store`, `Thumbs.db` - OS generated files

## Files được GIỮ LẠI:

### ✅ **Cần thiết cho build**
- `gradle/wrapper/gradle-wrapper.jar` - Gradle wrapper executable
- `gradle/wrapper/gradle-wrapper.properties` - Gradle wrapper config
- `gradlew`, `gradlew.bat` - Gradle wrapper scripts

### ✅ **Configuration files**
- `application.yml`, `application-dev.yml`, `application-docker.yml` - Spring configs
- `build.gradle`, `settings.gradle` - Build configuration
- Source code trong `src/`

### ✅ **Documentation**
- `README.md`, `*.md` - Documentation files
- `Dockerfile`, `docker-compose.yml` - Container configuration

## Kiểm tra ignore status:

```bash
# Kiểm tra file nào bị ignore
git check-ignore -v <file-path>

# Xem status của tất cả files
git status --ignored

# Force add file bị ignore (nếu cần)
git add -f <file-path>
```

## Lưu ý:
- File `.gitignore` trong backend/ chỉ áp dụng cho backend module
- File `.gitignore` ở root áp dụng cho toàn bộ project (Flutter + Backend)
- Nếu cần ignore file specific cho local development, dùng `.git/info/exclude` 