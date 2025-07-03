-- =============================================================================
-- JWT MOCK HELPERS FOR TESTING
-- Giả lập JWT authentication khi test hàm attendance_checkin_checkout
-- =============================================================================

-- =============================================================================
-- 1. HELPER FUNCTION: Set Mock JWT Claims
-- =============================================================================

CREATE OR REPLACE FUNCTION test_helpers.set_mock_jwt_claims(
    p_employee_email TEXT
) RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set mock JWT claims cho session hiện tại
    PERFORM set_config(
        'request.jwt.claims', 
        json_build_object('email', p_employee_email)::text,
        false  -- Apply to current session
    );
    
    RAISE NOTICE 'Mock JWT set for email: %', p_employee_email;
END;
$$;

-- =============================================================================
-- 2. HELPER FUNCTION: Clear Mock JWT Claims  
-- =============================================================================

CREATE OR REPLACE FUNCTION test_helpers.clear_mock_jwt_claims()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear JWT claims
    PERFORM set_config('request.jwt.claims', NULL, false);
    
    RAISE NOTICE 'Mock JWT cleared';
END;
$$;

-- =============================================================================
-- 3. HELPER FUNCTION: Test JWT Authentication
-- =============================================================================

CREATE OR REPLACE FUNCTION test_helpers.test_jwt_authentication(
    p_test_email TEXT DEFAULT 'mai.tran2@personaai.com'
) RETURNS TABLE (
    test_name TEXT,
    employee_id INTEGER,
    jwt_email TEXT,
    auth_success BOOLEAN
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_id INTEGER;
    v_jwt_email TEXT;
BEGIN
    -- Test 1: No JWT (should return NULL)
    PERFORM test_helpers.clear_mock_jwt_claims();
    SELECT mobile_api.get_current_user_id() INTO v_employee_id;
    
    RETURN QUERY SELECT 
        'No JWT Claims'::TEXT,
        v_employee_id,
        NULL::TEXT,
        (v_employee_id IS NULL) as auth_success;
    
    -- Test 2: Valid JWT với existing employee
    PERFORM test_helpers.set_mock_jwt_claims(p_test_email);
    SELECT mobile_api.get_current_user_id() INTO v_employee_id;
    
    BEGIN
        v_jwt_email := current_setting('request.jwt.claims', true)::json->>'email';
    EXCEPTION WHEN OTHERS THEN
        v_jwt_email := NULL;
    END;
    
    RETURN QUERY SELECT 
        'Valid JWT - Existing User'::TEXT,
        v_employee_id,
        v_jwt_email,
        (v_employee_id IS NOT NULL) as auth_success;
    
    -- Test 3: Valid JWT với non-existing employee
    PERFORM test_helpers.set_mock_jwt_claims('nonexist@test.com');
    SELECT mobile_api.get_current_user_id() INTO v_employee_id;
    
    RETURN QUERY SELECT 
        'Valid JWT - Non-existing User'::TEXT,
        v_employee_id,
        'nonexist@test.com'::TEXT,
        (v_employee_id IS NULL) as auth_success;
    
    -- Cleanup
    PERFORM test_helpers.clear_mock_jwt_claims();
END;
$$;

-- =============================================================================
-- 4. WRAPPER FUNCTION: Test Attendance với Mock JWT
-- =============================================================================

CREATE OR REPLACE FUNCTION test_helpers.test_attendance_with_mock_jwt(
    p_employee_email TEXT,
    p_action TEXT,
    p_latitude DECIMAL(10,8),
    p_longitude DECIMAL(11,8),
    p_gps_accuracy DECIMAL(6,2) DEFAULT 5.0,
    p_wifi_ssid TEXT DEFAULT 'Office-WiFi',
    p_wifi_bssid TEXT DEFAULT '00:11:22:33:44:55',
    p_device_info JSONB DEFAULT '{"device_id": "TEST-001", "os": "iOS 17.0"}'
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Set mock JWT claims
    PERFORM test_helpers.set_mock_jwt_claims(p_employee_email);
    
    -- Call attendance function
    SELECT mobile_api.attendance_checkin_checkout(
        p_action, p_latitude, p_longitude, p_gps_accuracy,
        p_wifi_ssid, p_wifi_bssid, p_device_info
    ) INTO v_result;
    
    -- Clear mock JWT (cleanup)
    PERFORM test_helpers.clear_mock_jwt_claims();
    
    RETURN v_result;
END;
$$;

-- =============================================================================
-- 5. BATCH TEST FUNCTION: Multiple Employees
-- =============================================================================

CREATE OR REPLACE FUNCTION test_helpers.batch_test_attendance(
    p_employee_emails TEXT[],
    p_action TEXT DEFAULT 'check_in'
) RETURNS TABLE (
    employee_email TEXT,
    result_success BOOLEAN,
    error_code TEXT,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_email TEXT;
    v_result JSONB;
BEGIN
    FOREACH v_email IN ARRAY p_employee_emails LOOP
        -- Test với mỗi employee
        SELECT test_helpers.test_attendance_with_mock_jwt(
            v_email,
            p_action,
            10.762622,  -- GPS coordinates
            106.660172,
            5.0,
            'Office-WiFi',
            '00:11:22:33:44:55',
            ('{"device_id": "TEST-' || v_email || '", "os": "iOS 17.0"}')::jsonb
        ) INTO v_result;
        
        RETURN QUERY SELECT 
            v_email,
            COALESCE((v_result->>'success')::boolean, false),
            COALESCE(v_result->>'error_code', 'UNKNOWN'),
            COALESCE(v_result->>'message', 'No message');
    END LOOP;
END;
$$;

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant permissions cho test functions
GRANT EXECUTE ON FUNCTION test_helpers.set_mock_jwt_claims(TEXT) TO mobile_user;
GRANT EXECUTE ON FUNCTION test_helpers.clear_mock_jwt_claims() TO mobile_user;
GRANT EXECUTE ON FUNCTION test_helpers.test_jwt_authentication(TEXT) TO mobile_user;
GRANT EXECUTE ON FUNCTION test_helpers.test_attendance_with_mock_jwt(TEXT, TEXT, DECIMAL, DECIMAL, DECIMAL, TEXT, TEXT, JSONB) TO mobile_user;
GRANT EXECUTE ON FUNCTION test_helpers.batch_test_attendance(TEXT[], TEXT) TO mobile_user;

-- =============================================================================
-- USAGE EXAMPLES
-- =============================================================================

/*
-- Example 1: Test JWT authentication
SELECT * FROM test_helpers.test_jwt_authentication('mai.tran2@personaai.com');

-- Example 2: Test attendance với mock JWT
SELECT test_helpers.test_attendance_with_mock_jwt(
    'mai.tran2@personaai.com',
    'check_in',
    10.762622,
    106.660172
);

-- Example 3: Batch test nhiều employees
SELECT * FROM test_helpers.batch_test_attendance(
    ARRAY['mai.tran2@personaai.com', 'cuong.pham3@personaai.com', 'duc.nguyen4@personaai.com'],
    'check_in'
);

-- Example 4: Manual mock JWT trong session
SELECT test_helpers.set_mock_jwt_claims('mai.tran2@personaai.com');
SELECT mobile_api.attendance_checkin_checkout('check_in', 10.762622, 106.660172, 5.0, 'Office-WiFi', '00:11:22:33:44:55', '{"device_id": "TEST"}');
SELECT test_helpers.clear_mock_jwt_claims();
*/ 