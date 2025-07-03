-- =============================================================================
-- SETUP TEST SCHEMA & ENVIRONMENT
-- Tạo các schema và data cần thiết cho test attendance system
-- =============================================================================

-- =============================================================================
-- 1. CREATE TEST SCHEMA
-- =============================================================================

-- Create test_helpers schema if not exists
CREATE SCHEMA IF NOT EXISTS test_helpers;

-- Grant permissions
GRANT USAGE ON SCHEMA test_helpers TO mobile_user;
GRANT CREATE ON SCHEMA test_helpers TO postgres;

-- =============================================================================
-- 2. CREATE TEST EMPLOYEES
-- =============================================================================

-- Insert test employees if not exist
DO $$
BEGIN
    -- Test Employee 1: Normal employee
    INSERT INTO public.employees (
        id, full_name, email_internal, employee_type
    ) VALUES (
        1, 'Test Employee 1', 'test1@personaai.com', 'fulltime'
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email_internal = EXCLUDED.email_internal;

    -- Test Employee 2: Another employee
    INSERT INTO public.employees (
        id, full_name, email_internal, employee_type
    ) VALUES (
        2, 'Test Employee 2', 'test2@personaai.com', 'fulltime'
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email_internal = EXCLUDED.email_internal;

    -- Test Employee 3: Inactive employee  
    INSERT INTO public.employees (
        id, full_name, email_internal, employee_type
    ) VALUES (
        999, 'Test Inactive Employee', 'inactive@personaai.com', NULL
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email_internal = EXCLUDED.email_internal;

    RAISE NOTICE 'Test employees created/updated';
END $$;

-- =============================================================================
-- 3. CREATE TEST WORKPLACE LOCATION
-- =============================================================================

DO $$
BEGIN
    -- Test workplace location
    INSERT INTO attendance.workplace_locations (
        id, name, address, latitude, longitude,
        gps_radius_meters, allowed_wifi_networks, require_gps, require_wifi, is_active
    ) VALUES (
        1, 'Văn phòng Test PersonaAI', '123 Test Street, HCMC', 
        10.762622, 106.660172,  -- GPS coordinates
        50,  -- 50 meters radius
        '[
            {"ssid": "Office-WiFi", "bssid": "00:11:22:33:44:55", "security": "WPA2"},
            {"ssid": "PersonaAI-5G", "bssid": "AA:BB:CC:DD:EE:FF", "security": "WPA3"}
        ]'::jsonb,
        true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        allowed_wifi_networks = EXCLUDED.allowed_wifi_networks;

    RAISE NOTICE 'Test workplace location created/updated';
END $$;

-- =============================================================================
-- 4. CREATE TEST WORK SHIFT
-- =============================================================================

DO $$
BEGIN
    -- Test work shift
    INSERT INTO attendance.work_shifts (
        id, name, start_time, end_time,
        late_threshold_minutes, early_leave_threshold_minutes,
        days_of_week, is_active
    ) VALUES (
        1, 'Ca hành chính Test', '08:00:00', '17:00:00',
        15, 15,  -- 15 minutes threshold
        '["monday", "tuesday", "wednesday", "thursday", "friday"]'::jsonb,
        true
    ) ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time;

    RAISE NOTICE 'Test work shift created/updated';
END $$;

-- =============================================================================
-- 5. CREATE TEST SHIFT ASSIGNMENTS
-- =============================================================================

DO $$
BEGIN
    -- Shift assignment cho test employee 1
    INSERT INTO attendance.shift_assignments (
        id, assignment_type, target_id, shift_id, location_id,
        effective_from, effective_to, is_active
    ) VALUES (
        1, 'employee', 1, 1, 1,
        CURRENT_DATE - INTERVAL '30 days', 
        CURRENT_DATE + INTERVAL '365 days', 
        true
    ) ON CONFLICT (id) DO UPDATE SET
        target_id = EXCLUDED.target_id,
        shift_id = EXCLUDED.shift_id,
        location_id = EXCLUDED.location_id;

    -- Shift assignment cho test employee 2
    INSERT INTO attendance.shift_assignments (
        id, assignment_type, target_id, shift_id, location_id,
        effective_from, effective_to, is_active
    ) VALUES (
        2, 'employee', 2, 1, 1,
        CURRENT_DATE - INTERVAL '30 days', 
        CURRENT_DATE + INTERVAL '365 days', 
        true
    ) ON CONFLICT (id) DO UPDATE SET
        target_id = EXCLUDED.target_id,
        shift_id = EXCLUDED.shift_id,
        location_id = EXCLUDED.location_id;

    RAISE NOTICE 'Test shift assignments created';
END $$;

-- =============================================================================
-- 6. CREATE TEST DEPARTMENTS & JOB TITLES (if needed)
-- =============================================================================
-- Note: Commented out because these tables may not exist in all environments
-- and are not required for basic attendance testing

-- DO $$
-- BEGIN
--     -- Test department
--     INSERT INTO public.departments (
--         id, name, description, is_active
--     ) VALUES (
--         1, 'Test Department', 'Department for testing', true
--     ) ON CONFLICT (id) DO UPDATE SET
--         name = EXCLUDED.name,
--         is_active = EXCLUDED.is_active;
-- 
--     -- Test job title
--     INSERT INTO public.job_titles (
--         id, title, description, is_active
--     ) VALUES (
--         1, 'Test Employee', 'Job title for testing', true
--     ) ON CONFLICT (id) DO UPDATE SET
--         title = EXCLUDED.title,
--         is_active = EXCLUDED.is_active;
-- 
--     RAISE NOTICE 'Test departments and job titles created/updated';
-- 
-- EXCEPTION
--     WHEN OTHERS THEN
--         -- Ignore if tables don't exist yet
--         RAISE NOTICE 'Skipped departments/job_titles setup (tables may not exist)';
-- END $$;

-- =============================================================================
-- 7. UTILITY FUNCTION: Reset Test Data
-- =============================================================================

CREATE OR REPLACE FUNCTION test_helpers.reset_test_data()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clean test attendance data
    DELETE FROM attendance.device_logs WHERE employee_id IN (1, 2, 999);
    DELETE FROM attendance.attendance_sessions WHERE employee_id IN (1, 2, 999);
    DELETE FROM attendance.attendance_records WHERE employee_id IN (1, 2, 999);
    DELETE FROM attendance.attendance_preapprovals WHERE employee_id IN (1, 2, 999);
    
    -- Reset any mock JWT claims
    PERFORM test_helpers.clear_mock_jwt_claims();
    
    RAISE NOTICE 'Test data reset completed';
END;
$$;

-- Grant permission
GRANT EXECUTE ON FUNCTION test_helpers.reset_test_data() TO mobile_user;

-- =============================================================================
-- 8. SUMMARY
-- =============================================================================

SELECT 
    'TEST ENVIRONMENT SETUP COMPLETED' as status,
    'Ready for attendance function testing' as message;

-- Show test data summary
SELECT 'TEST EMPLOYEES' as category, count(*) as count 
FROM public.employees WHERE id IN (1, 2, 999)
UNION ALL
SELECT 'TEST WORKPLACE LOCATIONS' as category, count(*) as count 
FROM attendance.workplace_locations WHERE id = 1
UNION ALL  
SELECT 'TEST WORK SHIFTS' as category, count(*) as count 
FROM attendance.work_shifts WHERE id = 1
UNION ALL
SELECT 'TEST SHIFT ASSIGNMENTS' as category, count(*) as count 
FROM attendance.shift_assignments WHERE target_id IN (1, 2) AND assignment_type = 'employee';

-- Test environment setup completed successfully!
-- You can now run attendance tests with JWT mock helpers.
-- Available test emails: test1@personaai.com, test2@personaai.com
-- Use test_helpers.reset_test_data() to clean up between tests. 