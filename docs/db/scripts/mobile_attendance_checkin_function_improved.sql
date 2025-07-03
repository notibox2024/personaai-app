-- =============================================================================
-- IMPROVED MOBILE ATTENDANCE CHECK-IN/CHECK-OUT FUNCTION
-- Xử lý edge cases: quên check-in, quên check-out, multiple sessions
-- =============================================================================

CREATE OR REPLACE FUNCTION mobile_api.attendance_checkin_checkout_v2(
    p_action TEXT,                    -- 'check_in' hoặc 'check_out'
    p_latitude DECIMAL(10,8),         -- GPS latitude  
    p_longitude DECIMAL(11,8),        -- GPS longitude
    p_gps_accuracy DECIMAL(6,2),      -- GPS accuracy (meters)
    p_wifi_ssid TEXT DEFAULT NULL,    -- WiFi SSID (optional)
    p_wifi_bssid TEXT DEFAULT NULL,   -- WiFi BSSID (optional) 
    p_device_info JSONB DEFAULT '{}', -- Device info JSON
    p_force_action BOOLEAN DEFAULT false, -- Force action nếu có conflict
    p_session_type TEXT DEFAULT 'work'     -- Session type: work, break, overtime
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_employee_id INTEGER;
    v_workplace_location RECORD;
    v_current_shift RECORD;
    v_device_log_id BIGINT;
    v_session_id BIGINT;
    v_validation_result JSONB;
    v_pre_approval RECORD;
    v_risk_score INTEGER := 0;
    v_current_session RECORD;
    v_orphaned_session RECORD;
    v_result JSONB;
    v_distance_meters DECIMAL;
    v_speed_kmh DECIMAL;
    v_wifi_valid BOOLEAN := false;
    v_gps_valid BOOLEAN := false;
    v_warning_messages TEXT[] := '{}';
BEGIN
    -- =================================================================
    -- 1. AUTHENTICATION & EMPLOYEE LOOKUP
    -- =================================================================
    
    SELECT mobile_api.get_current_user_id() INTO v_employee_id;
    
    IF v_employee_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'AUTH_REQUIRED',
            'message', 'Authentication required or employee not found'
        );
    END IF;

    -- =================================================================
    -- 2. VALIDATE INPUT PARAMETERS
    -- =================================================================
    
    IF p_action NOT IN ('check_in', 'check_out') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'INVALID_ACTION',
            'message', 'Action must be check_in or check_out'
        );
    END IF;
    
    IF p_gps_accuracy > 50 THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'GPS_ACCURACY_LOW',
            'message', 'GPS accuracy too low. Please try again outdoors.'
        );
    END IF;

    -- =================================================================
    -- 3. AUTO-HANDLE ORPHANED SESSIONS (Quên check-out hôm trước)
    -- =================================================================
    
    -- Tìm session cũ chưa được close
    SELECT * INTO v_orphaned_session
    FROM attendance.attendance_sessions
    WHERE employee_id = v_employee_id
        AND check_out_time IS NULL
        AND status = 'active'
        AND DATE(check_in_time) < CURRENT_DATE;
    
    -- Auto-close orphaned sessions
    IF v_orphaned_session IS NOT NULL THEN
        UPDATE attendance.attendance_sessions
        SET 
            check_out_time = DATE(check_in_time) + time '17:00:00', -- Default end time
            status = 'auto_closed',
            work_duration_minutes = EXTRACT(EPOCH FROM (
                DATE(check_in_time) + time '17:00:00' - check_in_time
            )) / 60,
            notes = 'Auto-closed due to missing checkout',
            last_modified_by = 'system_auto_close',
            last_modified_date = CURRENT_TIMESTAMP
        WHERE id = v_orphaned_session.id;
        
        v_warning_messages := array_append(v_warning_messages, 
            format('Auto-closed previous session from %s', v_orphaned_session.check_in_time::date));
    END IF;

    -- [... Existing location validation logic ...]
    -- Đặt ở đây logic GPS/WiFi validation từ function gốc

    -- =================================================================
    -- 4. ENHANCED BUSINESS LOGIC - CHECK-IN vs CHECK-OUT  
    -- =================================================================
    
    IF p_action = 'check_in' THEN
        
        -- Check for existing active session today
        SELECT * INTO v_current_session
        FROM attendance.attendance_sessions
        WHERE employee_id = v_employee_id
            AND DATE(check_in_time) = CURRENT_DATE
            AND check_out_time IS NULL
            AND status = 'active';
            
        IF v_current_session IS NOT NULL THEN
            IF p_force_action = false THEN
                RETURN jsonb_build_object(
                    'success', false,
                    'error_code', 'ALREADY_CHECKED_IN',
                    'message', 'You are already checked in today. Use force_action=true to create new session.',
                    'suggestion', 'multiple_session',
                    'current_session', jsonb_build_object(
                        'id', v_current_session.id,
                        'check_in_time', v_current_session.check_in_time,
                        'session_type', v_current_session.session_type
                    )
                );
            ELSE
                -- Force new session (break, overtime, etc.)
                v_warning_messages := array_append(v_warning_messages, 
                    format('Created additional %s session while %s session is active', 
                           p_session_type, v_current_session.session_type));
            END IF;
        END IF;
        
        -- Create new attendance session
        INSERT INTO attendance.attendance_sessions (
            employee_id, work_date, shift_id, location_id,
            check_in_time, session_type, status, is_pre_approved,
            created_by, created_date, last_modified_by, last_modified_date
        ) VALUES (
            v_employee_id, CURRENT_DATE, 
            v_current_shift.id, v_workplace_location.id,
            CURRENT_TIMESTAMP, p_session_type, 'active',
            v_pre_approval IS NOT NULL,
            'mobile_app', CURRENT_TIMESTAMP, 'mobile_app', CURRENT_TIMESTAMP
        ) RETURNING id INTO v_session_id;
        
    ELSE -- check_out
        
        -- Enhanced check-out logic
        SELECT * INTO v_current_session
        FROM attendance.attendance_sessions  
        WHERE employee_id = v_employee_id
            AND DATE(check_in_time) = CURRENT_DATE
            AND check_out_time IS NULL
            AND status = 'active'
        ORDER BY check_in_time DESC  -- Get latest session
        LIMIT 1;
            
        IF v_current_session IS NULL THEN
            IF p_force_action = false THEN
                RETURN jsonb_build_object(
                    'success', false,
                    'error_code', 'NO_ACTIVE_SESSION',
                    'message', 'No active check-in session found for today. Use force_action=true to create missing check-in.',
                    'suggestion', 'missing_checkin',
                    'recommended_action', jsonb_build_object(
                        'action', 'Create backdated check-in session',
                        'estimated_checkin', (CURRENT_TIMESTAMP - interval '8 hours')
                    )
                );
            ELSE
                -- CREATE MISSING CHECK-IN session
                INSERT INTO attendance.attendance_sessions (
                    employee_id, work_date, shift_id, location_id,
                    check_in_time, check_out_time, session_type, status,
                    work_duration_minutes, notes,
                    created_by, created_date, last_modified_by, last_modified_date
                ) VALUES (
                    v_employee_id, CURRENT_DATE, 
                    v_current_shift.id, v_workplace_location.id,
                    CURRENT_TIMESTAMP - interval '8 hours', -- Estimated check-in
                    CURRENT_TIMESTAMP,
                    'work', 'completed',
                    EXTRACT(EPOCH FROM interval '8 hours') / 60,
                    'System-generated session due to missing check-in',
                    'mobile_app', CURRENT_TIMESTAMP, 'mobile_app', CURRENT_TIMESTAMP
                ) RETURNING id INTO v_session_id;
                
                v_warning_messages := array_append(v_warning_messages, 
                    'Created missing check-in session with estimated time');
            END IF;
        ELSE
            -- Normal check-out
            UPDATE attendance.attendance_sessions
            SET 
                check_out_time = CURRENT_TIMESTAMP,
                status = 'completed',
                work_duration_minutes = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - check_in_time)) / 60,
                last_modified_by = 'mobile_app',
                last_modified_date = CURRENT_TIMESTAMP
            WHERE id = v_current_session.id;
            
            v_session_id := v_current_session.id;
        END IF;
        
    END IF;

    -- =================================================================
    -- 5. ENHANCED DAILY ATTENDANCE RECORD UPDATE
    -- =================================================================
    
    -- Calculate aggregated data from all sessions today
    WITH daily_summary AS (
        SELECT 
            COALESCE(SUM(work_duration_minutes), 0) as total_minutes,
            MIN(check_in_time) as first_checkin,
            MAX(check_out_time) as last_checkout,
            COUNT(*) as session_count,
            array_agg(DISTINCT session_type) as session_types
        FROM attendance.attendance_sessions
        WHERE employee_id = v_employee_id 
            AND work_date = CURRENT_DATE
            AND status IN ('completed', 'active')
    )
    INSERT INTO attendance.attendance_records (
        employee_id, work_date, shift_id, location_id,
        actual_check_in, actual_check_out, total_work_minutes,
        check_in_gps_lat, check_in_gps_lng, 
        check_in_wifi_data, check_out_wifi_data, mobile_device_info,
        status, check_in_source, check_out_source,
        notes,
        created_by, created_date, last_modified_by, last_modified_date
    )
    SELECT 
        v_employee_id, CURRENT_DATE, v_current_shift.id, v_workplace_location.id,
        ds.first_checkin,
        ds.last_checkout,
        ds.total_minutes,
        CASE WHEN p_action = 'check_in' THEN p_latitude ELSE NULL END,
        CASE WHEN p_action = 'check_in' THEN p_longitude ELSE NULL END,
        CASE WHEN p_action = 'check_in' THEN 
            jsonb_build_object('ssid', p_wifi_ssid, 'bssid', p_wifi_bssid, 'validated', v_wifi_valid) 
        ELSE NULL END,
        CASE WHEN p_action = 'check_out' THEN 
            jsonb_build_object('ssid', p_wifi_ssid, 'bssid', p_wifi_bssid, 'validated', v_wifi_valid) 
        ELSE NULL END,
        p_device_info,
        CASE 
            WHEN ds.last_checkout IS NULL THEN 'incomplete'::attendance.attendance_status
            WHEN array_length(v_warning_messages, 1) > 0 THEN 'adjusted'::attendance.attendance_status
            ELSE 'normal'::attendance.attendance_status 
        END,
        CASE WHEN p_action = 'check_in' THEN 'app'::attendance.check_source ELSE NULL END,
        CASE WHEN p_action = 'check_out' THEN 'app'::attendance.check_source ELSE NULL END,
        CASE 
            WHEN array_length(v_warning_messages, 1) > 0 THEN array_to_string(v_warning_messages, '; ')
            ELSE NULL 
        END,
        'mobile_app', CURRENT_TIMESTAMP, 'mobile_app', CURRENT_TIMESTAMP
    FROM daily_summary ds
    ON CONFLICT (employee_id, work_date) DO UPDATE SET
        actual_check_out = EXCLUDED.actual_check_out,
        total_work_minutes = EXCLUDED.total_work_minutes,
        check_out_wifi_data = CASE 
            WHEN p_action = 'check_out' THEN EXCLUDED.check_out_wifi_data 
            ELSE attendance_records.check_out_wifi_data 
        END,
        status = EXCLUDED.status,
        notes = COALESCE(EXCLUDED.notes, attendance_records.notes),
        last_modified_by = 'mobile_app',
        last_modified_date = CURRENT_TIMESTAMP;

    -- =================================================================
    -- 6. RETURN ENHANCED RESPONSE
    -- =================================================================
    
    RETURN jsonb_build_object(
        'success', true,
        'action', p_action,
        'session_id', v_session_id,
        'session_type', p_session_type,
        'timestamp', CURRENT_TIMESTAMP,
        'message', CASE 
            WHEN p_action = 'check_in' THEN 'Successfully checked in'
            ELSE 'Successfully checked out'
        END,
        'warnings', CASE 
            WHEN array_length(v_warning_messages, 1) > 0 THEN v_warning_messages
            ELSE null
        END,
        'daily_summary', jsonb_build_object(
            'total_sessions_today', (
                SELECT COUNT(*) FROM attendance.attendance_sessions 
                WHERE employee_id = v_employee_id AND work_date = CURRENT_DATE
            ),
            'total_work_minutes', (
                SELECT COALESCE(SUM(work_duration_minutes), 0) 
                FROM attendance.attendance_sessions 
                WHERE employee_id = v_employee_id AND work_date = CURRENT_DATE 
                    AND status = 'completed'
            ),
            'active_sessions', (
                SELECT COUNT(*) FROM attendance.attendance_sessions 
                WHERE employee_id = v_employee_id AND work_date = CURRENT_DATE 
                    AND check_out_time IS NULL
            )
        ),
        'location_info', jsonb_build_object(
            'workplace_name', v_workplace_location.name,
            'distance_meters', round(v_distance_meters, 1),
            'validation_passed', v_gps_valid OR v_wifi_valid
        )
    );

EXCEPTION 
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'SYSTEM_ERROR',
            'message', 'An unexpected error occurred. Please try again.',
            'debug_info', CASE 
                WHEN current_setting('app.debug_mode', true) = 'true' THEN
                    jsonb_build_object('error', SQLERRM, 'detail', SQLSTATE)
                ELSE null
            END
        );
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION mobile_api.attendance_checkin_checkout_v2(TEXT, DECIMAL, DECIMAL, DECIMAL, TEXT, TEXT, JSONB, BOOLEAN, TEXT) TO mobile_user;

COMMENT ON FUNCTION mobile_api.attendance_checkin_checkout_v2(TEXT, DECIMAL, DECIMAL, DECIMAL, TEXT, TEXT, JSONB, BOOLEAN, TEXT) IS 
'Enhanced mobile attendance với edge case handling:
- Auto-close orphaned sessions
- Force actions cho missing check-in/out  
- Multiple session support (work, break, overtime)
- Comprehensive warning system
- Aggregated daily summary calculation'; 