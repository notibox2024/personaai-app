#!/bin/bash

# Script to benchmark PersonaAI Docker services startup performance
# Usage: ./startup-benchmark.sh

set -e

COMPOSE_FILE="docker-compose.yml"
LOG_FILE="startup-benchmark-$(date +%Y%m%d_%H%M%S).log"

echo "🚀 PersonaAI Docker Startup Benchmark"
echo "======================================"
echo "Log file: $LOG_FILE"

# Function to log with timestamp
log_with_time() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to measure service startup time
measure_service_startup() {
    local service_name=$1
    local check_command=$2
    local max_wait=${3:-120}
    
    log_with_time "⏱️  Measuring $service_name startup time..."
    
    local start_time=$(date +%s)
    local timeout=$max_wait
    
    while [ $timeout -gt 0 ]; do
        if eval "$check_command" > /dev/null 2>&1; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log_with_time "✅ $service_name ready in ${duration}s"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_with_time "❌ $service_name failed to start in ${duration}s"
    return 1
}

# Stop existing containers
log_with_time "🛑 Stopping existing containers..."
docker-compose down -v > /dev/null 2>&1 || true

# Start benchmark
overall_start=$(date +%s)
log_with_time "🚀 Starting all services..."

# Start services in background
docker-compose up -d > /dev/null 2>&1

# Measure each service startup time
log_with_time "📊 Measuring individual service startup times..."

# PostgreSQL (should start first)
measure_service_startup "PostgreSQL" \
    "docker-compose exec -T postgres pg_isready -U postgres -d personaai" \
    60

# Redis (independent startup)
measure_service_startup "Redis" \
    "docker-compose exec -T redis redis-cli ping | grep -q PONG" \
    30

# Keycloak (depends on PostgreSQL)
measure_service_startup "Keycloak" \
    "curl -s -f http://localhost:9000/health/ready" \
    90

# PostgREST (depends on PostgreSQL and Keycloak)
measure_service_startup "PostgREST" \
    "curl -s -f http://localhost:3000/" \
    60

# Calculate overall time
overall_end=$(date +%s)
overall_duration=$((overall_end - overall_start))

log_with_time "⏱️  Overall startup time: ${overall_duration}s"

# Display resource usage
log_with_time "💾 Resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | tee -a "$LOG_FILE"

# Display container status
log_with_time "📦 Container status:"
docker-compose ps | tee -a "$LOG_FILE"

# Performance analysis
log_with_time "📈 Performance Analysis:"
echo "=====================================" | tee -a "$LOG_FILE"

if [ $overall_duration -lt 60 ]; then
    echo "🚀 Excellent! Overall startup < 1 minute" | tee -a "$LOG_FILE"
elif [ $overall_duration -lt 120 ]; then
    echo "👍 Good! Overall startup < 2 minutes" | tee -a "$LOG_FILE"
elif [ $overall_duration -lt 180 ]; then
    echo "⚠️  Acceptable. Overall startup < 3 minutes" | tee -a "$LOG_FILE"
else
    echo "🐌 Slow. Overall startup > 3 minutes - needs optimization" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "💡 Tips for faster startup:" | tee -a "$LOG_FILE"
echo "- Increase Docker memory allocation" | tee -a "$LOG_FILE"
echo "- Use SSD for Docker volumes" | tee -a "$LOG_FILE"
echo "- Reduce init script complexity" | tee -a "$LOG_FILE"
echo "- Use image caching" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
log_with_time "✨ Benchmark completed! Check $LOG_FILE for detailed logs." 