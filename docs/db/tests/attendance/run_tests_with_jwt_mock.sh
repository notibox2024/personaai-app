#!/bin/bash

# =============================================================================
# ATTENDANCE TESTS WITH JWT MOCK RUNNER
# Chạy test attendance function với JWT authentication mock
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection settings
DB_CONTAINER="personaai-postgres"
DB_USER="postgres"
DB_NAME="personaai"

# Test files (trong thứ tự chạy)
SETUP_SCHEMA_FILE="00_setup_test_schema.sql"
JWT_MOCK_HELPERS_FILE="test_jwt_mock_helpers.sql"
MAIN_TEST_FILE="test_attendance_with_jwt_mock.sql"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is available and container is running
check_container() {
    print_color $BLUE "🔍 Checking Docker and database container..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_color $RED "❌ Docker is not installed or not in PATH!"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_color $RED "❌ Docker daemon is not running!"
        exit 1
    fi
    
    # Check if container exists and is running
    if ! docker ps | grep -q $DB_CONTAINER; then
        print_color $RED "❌ Container $DB_CONTAINER is not running!"
        
        # Check if container exists but is stopped
        if docker ps -a | grep -q $DB_CONTAINER; then
            print_color $YELLOW "🔄 Starting stopped container..."
            docker start $DB_CONTAINER || {
                print_color $RED "❌ Failed to start container!"
                exit 1
            }
            sleep 5
        else
            print_color $RED "❌ Container $DB_CONTAINER does not exist!"
            print_color $YELLOW "💡 Please create and start the PostgreSQL container first"
            exit 1
        fi
    fi
    
    print_color $GREEN "✅ Container $DB_CONTAINER is running"
}

# Function to test database connection
test_connection() {
    print_color $BLUE "🔍 Testing database connection..."
    
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT 'Connection successful' as status;" > /dev/null 2>&1 || {
        print_color $RED "❌ Database connection failed!"
        exit 1
    }
    
    print_color $GREEN "✅ Database connection successful"
}

# Function to check if required schemas and tables exist
check_database_schema() {
    print_color $BLUE "🔍 Checking database schema..."
    
    # Check if required schemas exist
    local schemas=("attendance" "mobile_api")
    for schema in "${schemas[@]}"; do
        if ! docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT 1 FROM information_schema.schemata WHERE schema_name = '$schema';" | grep -q "1"; then
            print_color $RED "❌ Schema $schema does not exist!"
            print_color $YELLOW "💡 Please setup the attendance system database schema first"
            exit 1
        fi
    done
    
    # Check if required tables exist
    local tables=(
        "public.employees"
        "attendance.workplace_locations"
        "attendance.work_shifts"
        "attendance.shift_assignments"
        "attendance.attendance_sessions"
        "attendance.device_logs"
        "attendance.attendance_records"
    )
    
    for table in "${tables[@]}"; do
        local schema=$(echo $table | cut -d. -f1)
        local tbl=$(echo $table | cut -d. -f2)
        if ! docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT 1 FROM information_schema.tables WHERE table_schema = '$schema' AND table_name = '$tbl';" | grep -q "1"; then
            print_color $RED "❌ Table $table does not exist!"
            print_color $YELLOW "💡 Please setup the attendance system database schema first"
            exit 1
        fi
    done
    
    print_color $GREEN "✅ Database schema is ready"
}

# Function to check if required functions exist
check_functions() {
    print_color $BLUE "🔍 Checking required functions..."
    
    local functions=(
        "mobile_api.attendance_checkin_checkout"
        "mobile_api.get_current_user_id"
    )
    
    for func in "${functions[@]}"; do
        if ! docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT 1 FROM pg_proc WHERE proname = '$(echo $func | cut -d. -f2)';" | grep -q "1"; then
            print_color $RED "❌ Function $func does not exist!"
            print_color $YELLOW "💡 Please install the attendance system functions first"
            exit 1
        fi
    done
    
    print_color $GREEN "✅ All required functions exist"
}

# Function to setup test environment
setup_test_environment() {
    print_color $BLUE "🏗️ Setting up test environment..."
    
    if [ ! -f "$SETUP_SCHEMA_FILE" ]; then
        print_color $RED "❌ Setup file $SETUP_SCHEMA_FILE not found!"
        exit 1
    fi
    
    print_color $YELLOW "📝 Creating test schema and data..."
    
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -f /dev/stdin << EOF
$(cat $SETUP_SCHEMA_FILE)
EOF
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ Test environment setup completed"
    else
        print_color $RED "❌ Test environment setup failed"
        exit 1
    fi
}

# Function to install JWT mock helpers
install_jwt_mock_helpers() {
    print_color $BLUE "🎭 Installing JWT mock helpers..."
    
    if [ ! -f "$JWT_MOCK_HELPERS_FILE" ]; then
        print_color $RED "❌ JWT mock helpers file $JWT_MOCK_HELPERS_FILE not found!"
        exit 1
    fi
    
    print_color $YELLOW "📝 Creating JWT mock functions..."
    
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -f /dev/stdin << EOF
$(cat $JWT_MOCK_HELPERS_FILE)
EOF
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ JWT mock helpers installed successfully"
    else
        print_color $RED "❌ JWT mock helpers installation failed"
        exit 1
    fi
}

# Function to run main tests
run_main_tests() {
    print_color $BLUE "🧪 Running attendance tests with JWT mock..."
    
    if [ ! -f "$MAIN_TEST_FILE" ]; then
        print_color $RED "❌ Main test file $MAIN_TEST_FILE not found!"
        exit 1
    fi
    
    print_color $YELLOW "📝 Executing test cases..."
    
    # Run tests with direct output (no file capture)
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -f /dev/stdin << EOF
-- Enable timing and formatting for better output
\timing off
\x auto

-- Run the main test file
$(cat $MAIN_TEST_FILE)
EOF
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ All tests completed successfully"
    else
        print_color $RED "❌ Some tests failed"
        exit 1
    fi
}

# Function to verify JWT mock functionality
verify_jwt_mock() {
    print_color $BLUE "🔍 Verifying JWT mock functionality..."
    
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
        -- Test JWT mock functions
        SELECT test_helpers.set_mock_jwt_claims('mai.tran2@personaai.com');
        SELECT mobile_api.get_current_user_id() as user_id_with_mock;
        SELECT test_helpers.clear_mock_jwt_claims();
        SELECT mobile_api.get_current_user_id() as user_id_without_mock;
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ JWT mock functionality verified"
    else
        print_color $RED "❌ JWT mock verification failed"
        exit 1
    fi
}

# Function to show test summary
show_test_summary() {
    print_color $BLUE "📊 Generating test summary..."
    
    docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
        -- Test data summary
        SELECT 
            'TEST SUMMARY' as section,
            'Device Logs: ' || COUNT(*) as device_logs
        FROM attendance.device_logs 
        WHERE employee_id IN (1, 2) 
            AND created_at >= CURRENT_DATE;
            
        SELECT 
            'SESSIONS TODAY' as section,
            'Sessions: ' || COUNT(*) as attendance_sessions
        FROM attendance.attendance_sessions
        WHERE employee_id IN (1, 2)
            AND work_date >= CURRENT_DATE;
    "
}

# Function to cleanup test data
cleanup_test_data() {
    print_color $YELLOW "🧹 Cleaning up test data..."
    
    read -p "Are you sure you want to cleanup test data? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "
            SELECT test_helpers.reset_test_data();
        "
        print_color $GREEN "✅ Test data cleaned up"
    else
        print_color $YELLOW "⏭️ Cleanup skipped"
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -s, --setup          Setup test environment only"
    echo "  -t, --test           Run tests only (requires setup)"
    echo "  -c, --cleanup        Cleanup test data"
    echo "  -v, --verify         Verify JWT mock functionality"
    echo "  -r, --report         Show test summary"
    echo "  --check              Check database schema and functions"
    echo "  -h, --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0                   Run full test suite (setup + test)"
    echo "  $0 -s                Setup test environment only"
    echo "  $0 -t                Run tests only"
    echo "  $0 -c                Cleanup test data"
    echo "  $0 -v                Verify JWT mock works"
    echo "  $0 --check           Check if database is ready for tests"
}

# Main function
main() {
    local setup_only=false
    local test_only=false
    local cleanup_only=false
    local verify_only=false
    local report_only=false
    local check_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--setup)
                setup_only=true
                shift
                ;;
            -t|--test)
                test_only=true
                shift
                ;;
            -c|--cleanup)
                cleanup_only=true
                shift
                ;;
            -v|--verify)
                verify_only=true
                shift
                ;;
            -r|--report)
                report_only=true
                shift
                ;;
            --check)
                check_only=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_color $RED "❌ Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Header
    print_color $BLUE "🚀 ATTENDANCE TESTS WITH JWT MOCK RUNNER"
    print_color $BLUE "========================================"
    
    # Pre-checks
    check_container
    test_connection
    check_database_schema
    
    # Execute based on options
    if [ "$cleanup_only" = true ]; then
        cleanup_test_data
    elif [ "$verify_only" = true ]; then
        check_functions
        verify_jwt_mock
    elif [ "$report_only" = true ]; then
        show_test_summary
    elif [ "$check_only" = true ]; then
        check_functions
        print_color $GREEN "✅ Database is ready for tests"
    elif [ "$setup_only" = true ]; then
        setup_test_environment
        install_jwt_mock_helpers
        verify_jwt_mock
    elif [ "$test_only" = true ]; then
        check_functions
        verify_jwt_mock
        run_main_tests
        show_test_summary
    else
        # Full test suite
        check_functions
        setup_test_environment
        install_jwt_mock_helpers
        verify_jwt_mock
        run_main_tests
        show_test_summary
    fi
    
    # Footer
    print_color $GREEN "🎉 Operation completed successfully!"
}

# Check if we're in the right directory
if [ ! -f "$SETUP_SCHEMA_FILE" ] || [ ! -f "$JWT_MOCK_HELPERS_FILE" ] || [ ! -f "$MAIN_TEST_FILE" ]; then
    print_color $RED "❌ Test files not found in current directory!"
    print_color $YELLOW "💡 Please run this script from the docs/db/tests/attendance/ directory"
    exit 1
fi

# Run main function with all arguments
main "$@" 