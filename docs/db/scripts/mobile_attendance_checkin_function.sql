-- =============================================================================
-- MOBILE ATTENDANCE CHECK-IN/CHECK-OUT FUNCTION
-- Schema: mobile_api (PostgREST exposed)
-- Purpose: Handle mobile attendance check-in/check-out with full validation
-- =============================================================================

CREATE OR REPLACE FUNCTION mobile_api.attendance_checkin_checkout(
    p_action TEXT,                    -- 'check_in' hoặc 'check_out'
    p_latitude DECIMAL(10,8),         -- GPS latitude  
    p_longitude DECIMAL(11,8),        -- GPS longitude
    p_gps_accuracy DECIMAL(6,2),      -- GPS accuracy (meters)
    p_wifi_ssid TEXT DEFAULT NULL,    -- WiFi SSID (optional)
    p_wifi_bssid TEXT DEFAULT NULL,   -- WiFi BSSID (optional) 
    p_device_info JSONB DEFAULT '{}'  -- Device info JSON
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_employee_id INTEGER;
    v_workplace_location RECORD;
    v_current_shift RECORD;
    v_device_log_id UUID;
    v_session_id UUID;
    v_validation_result JSONB;
    v_pre_approval RECORD;
    v_risk_score INTEGER := 0;
    v_current_session RECORD;
    v_result JSONB;
    v_distance_meters DECIMAL;
    v_wifi_valid BOOLEAN := false;
    v_gps_valid BOOLEAN := false;
BEGIN
    -- =================================================================
    -- 1. AUTHENTICATION & EMPLOYEE LOOKUP
    -- =================================================================
    
    -- Get current user ID từ JWT token (optimized)
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
    
    IF p_gps_accuracy > 50 THEN -- GPS accuracy quá thấp
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'GPS_ACCURACY_LOW',
            'message', 'GPS accuracy too low. Please try again outdoors.'
        );
    END IF;

    -- =================================================================
    -- 3. DETERMINE CURRENT SHIFT & WORKPLACE
    -- =================================================================
    
    -- Lấy shift assignment cho employee (priority logic)
    WITH shift_priority AS (
        SELECT 
            sa.shift_id,
            sa.location_id,
            CASE sa.assignment_type 
                WHEN 'employee' THEN 1
                WHEN 'position' THEN 2  
                WHEN 'department' THEN 3
            END as priority
        FROM attendance.shift_assignments sa
        JOIN public.employees e ON (
            (sa.assignment_type = 'employee' AND sa.target_id = e.id) OR
            (sa.assignment_type = 'position' AND sa.target_id = e.job_title_id) OR  
            (sa.assignment_type = 'department' AND sa.target_id = e.department_id)
        )
        WHERE e.id = v_employee_id
            AND CURRENT_DATE BETWEEN sa.effective_from AND COALESCE(sa.effective_to, '2099-12-31')
            AND sa.is_active = true
        ORDER BY priority
        LIMIT 1
    )
    SELECT ws.*, sp.location_id as assigned_location_id
    INTO v_current_shift
    FROM shift_priority sp
    JOIN attendance.work_shifts ws ON ws.id = sp.shift_id;
    
    IF v_current_shift IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'NO_SHIFT_ASSIGNED',
            'message', 'No work shift assigned for today'
        );
    END IF;

    -- =================================================================
    -- 4. LOCATION VALIDATION
    -- =================================================================
    
    -- Lấy workplace location
    SELECT * INTO v_workplace_location 
    FROM attendance.workplace_locations 
    WHERE id = v_current_shift.assigned_location_id AND is_active = true;
    
    IF v_workplace_location IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'WORKPLACE_NOT_FOUND',
            'message', 'Workplace location not configured'
        );
    END IF;
    
    -- GPS Validation
    SELECT ST_Distance(
        ST_GeogFromText('POINT(' || p_longitude || ' ' || p_latitude || ')'),
        ST_GeogFromText('POINT(' || v_workplace_location.longitude || ' ' || v_workplace_location.latitude || ')')
    ) INTO v_distance_meters;
    
    v_gps_valid := (v_distance_meters <= v_workplace_location.gps_radius_meters);
    
    -- WiFi Validation (nếu có config)
    IF v_workplace_location.wifi_networks IS NOT NULL AND jsonb_array_length(v_workplace_location.wifi_networks) > 0 THEN
        
        CASE v_workplace_location.validation_mode
            WHEN 'strict' THEN
                -- Require exact SSID + BSSID match
                SELECT COUNT(*) > 0 INTO v_wifi_valid
                FROM jsonb_array_elements(v_workplace_location.wifi_networks) network
                WHERE network->>'ssid' = p_wifi_ssid 
                    AND network->>'bssid' = p_wifi_bssid;
                    
            WHEN 'ssid_only' THEN  
                -- Allow any BSSID with correct SSID
                SELECT COUNT(*) > 0 INTO v_wifi_valid
                FROM jsonb_array_elements(v_workplace_location.wifi_networks) network
                WHERE network->>'ssid' = p_wifi_ssid;
                
            WHEN 'flexible' THEN
                -- Try BSSID first, fallback to SSID
                SELECT COUNT(*) > 0 INTO v_wifi_valid  
                FROM jsonb_array_elements(v_workplace_location.wifi_networks) network
                WHERE network->>'ssid' = p_wifi_ssid 
                    AND (network->>'bssid' IS NULL OR network->>'bssid' = p_wifi_bssid);
                    
            WHEN 'gps_only' THEN
                v_wifi_valid := true; -- Skip WiFi validation
        END CASE;
        
        -- Location validation result
        IF NOT (v_gps_valid OR v_wifi_valid) THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'LOCATION_INVALID',
                'message', 'You are not at the designated workplace location',
                'debug_info', jsonb_build_object(
                    'distance_meters', v_distance_meters,
                    'gps_valid', v_gps_valid,
                    'wifi_valid', v_wifi_valid
                )
            );
        END IF;
    ELSE
        -- Only GPS validation 
        IF NOT v_gps_valid THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'LOCATION_INVALID', 
                'message', format('You are %.0fm away from workplace (max: %sm)', 
                    v_distance_meters, v_workplace_location.gps_radius_meters)
            );
        END IF;
        v_wifi_valid := true; -- No WiFi required
    END IF;

    -- =================================================================
    -- 5. CHECK PRE-APPROVALS
    -- =================================================================
    
    SELECT * INTO v_pre_approval
    FROM attendance.attendance_preapprovals
    WHERE employee_id = v_employee_id
        AND request_date = CURRENT_DATE
        AND status = 'approved'
        AND (
            (p_action = 'check_in' AND request_type IN ('late_arrival', 'schedule_adjustment')) OR
            (p_action = 'check_out' AND request_type IN ('early_leave', 'schedule_adjustment'))
        )
    ORDER BY created_date DESC
    LIMIT 1;

    -- =================================================================
    -- 6. FRAUD DETECTION & RISK SCORING
    -- =================================================================
    
    -- Check multiple device usage
    IF EXISTS (
        SELECT 1 FROM attendance.device_logs
        WHERE employee_id = v_employee_id
            AND created_date >= CURRENT_TIMESTAMP - INTERVAL '30 minutes'
            AND device_info->>'device_id' != p_device_info->>'device_id'
    ) THEN
        v_risk_score := v_risk_score + 30;
    END IF;
    
    -- Check impossible location jump
    WITH last_location AS (
        SELECT latitude, longitude, created_date
        FROM attendance.device_logs  
        WHERE employee_id = v_employee_id
            AND latitude IS NOT NULL
        ORDER BY created_date DESC
        LIMIT 1
    )
    SELECT ST_Distance(
        ST_GeogFromText('POINT(' || ll.longitude || ' ' || ll.latitude || ')'),
        ST_GeogFromText('POINT(' || p_longitude || ' ' || p_latitude || ')')
    ) / EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ll.created_date)) * 3.6 as speed_kmh
    INTO v_distance_meters
    FROM last_location ll;
    
    IF v_distance_meters > 100 THEN -- Faster than 100km/h
        v_risk_score := v_risk_score + 50;
    END IF;

    -- =================================================================
    -- 7. BUSINESS LOGIC - CHECK-IN vs CHECK-OUT  
    -- =================================================================
    
    IF p_action = 'check_in' THEN
        
        -- Check if already checked in today
        SELECT * INTO v_current_session
        FROM attendance.attendance_sessions
        WHERE employee_id = v_employee_id
            AND DATE(check_in_time) = CURRENT_DATE
            AND check_out_time IS NULL;
            
        IF v_current_session IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'ALREADY_CHECKED_IN',
                'message', 'You are already checked in today',
                'session_id', v_current_session.id,
                'check_in_time', v_current_session.check_in_time
            );
        END IF;
        
        -- Create new attendance session
        INSERT INTO attendance.attendance_sessions (
            id, employee_id, work_date, shift_id, location_id,
            check_in_time, session_type, status, is_pre_approved
        ) VALUES (
            gen_random_uuid(), v_employee_id, CURRENT_DATE, 
            v_current_shift.id, v_workplace_location.id,
            CURRENT_TIMESTAMP, 'work', 'active',
            v_pre_approval IS NOT NULL
        ) RETURNING id INTO v_session_id;
        
    ELSE -- check_out
        
        -- Find active session to close
        SELECT * INTO v_current_session
        FROM attendance.attendance_sessions  
        WHERE employee_id = v_employee_id
            AND DATE(check_in_time) = CURRENT_DATE
            AND check_out_time IS NULL
            AND status = 'active';
            
        IF v_current_session IS NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'NO_ACTIVE_SESSION',
                'message', 'No active check-in session found for today'
            );
        END IF;
        
        -- Update session with check-out
        UPDATE attendance.attendance_sessions
        SET 
            check_out_time = CURRENT_TIMESTAMP,
            status = 'completed',
            work_duration_minutes = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - check_in_time)) / 60
        WHERE id = v_current_session.id;
        
        v_session_id := v_current_session.id;
        
    END IF;

    -- =================================================================
    -- 8. LOG RAW DEVICE DATA  
    -- =================================================================
    
    INSERT INTO attendance.device_logs (
        id, employee_id, device_type, source, action,
        latitude, longitude, gps_accuracy, 
        wifi_ssid, wifi_bssid, device_info,
        validation_result, risk_score, session_id
    ) VALUES (
        gen_random_uuid(), v_employee_id, 'mobile', 'app', p_action,
        p_latitude, p_longitude, p_gps_accuracy,
        p_wifi_ssid, p_wifi_bssid, p_device_info,
        jsonb_build_object(
            'gps_valid', v_gps_valid,
            'wifi_valid', v_wifi_valid, 
            'distance_meters', v_distance_meters,
            'pre_approved', v_pre_approval IS NOT NULL
        ),
        CASE 
            WHEN v_risk_score >= 80 THEN 'high'::attendance.risk_level
            WHEN v_risk_score >= 40 THEN 'medium'::attendance.risk_level  
            ELSE 'low'::attendance.risk_level
        END,
        v_session_id
    ) RETURNING id INTO v_device_log_id;

    -- =================================================================
    -- 9. UPDATE DAILY ATTENDANCE RECORD
    -- =================================================================
    
    -- Upsert attendance_records cho ngày hiện tại
    INSERT INTO attendance.attendance_records (
        employee_id, work_date, shift_id, location_id,
        first_check_in, last_check_out, total_work_minutes,
        status, check_in_source, check_out_source
    ) VALUES (
        v_employee_id, CURRENT_DATE, v_current_shift.id, v_workplace_location.id,
        CASE WHEN p_action = 'check_in' THEN CURRENT_TIMESTAMP END,
        CASE WHEN p_action = 'check_out' THEN CURRENT_TIMESTAMP END,
        CASE WHEN p_action = 'check_out' THEN 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_current_session.check_in_time)) / 60
        ELSE 0 END,
        'incomplete', 'app',
        CASE WHEN p_action = 'check_out' THEN 'app' END
    )
    ON CONFLICT (employee_id, work_date) DO UPDATE SET
        last_check_out = CASE WHEN p_action = 'check_out' THEN CURRENT_TIMESTAMP ELSE attendance_records.last_check_out END,
        check_out_source = CASE WHEN p_action = 'check_out' THEN 'app' ELSE attendance_records.check_out_source END,
        total_work_minutes = CASE WHEN p_action = 'check_out' THEN 
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - attendance_records.first_check_in)) / 60
        ELSE attendance_records.total_work_minutes END,
        status = CASE 
            WHEN p_action = 'check_out' THEN 'normal'::attendance.attendance_status
            ELSE attendance_records.status 
        END;

    -- =================================================================
    -- 10. RETURN SUCCESS RESPONSE
    -- =================================================================
    
    RETURN jsonb_build_object(
        'success', true,
        'action', p_action,
        'session_id', v_session_id,
        'timestamp', CURRENT_TIMESTAMP,
        'message', CASE 
            WHEN p_action = 'check_in' THEN 'Successfully checked in'
            ELSE 'Successfully checked out'
        END,
        'location_info', jsonb_build_object(
            'workplace_name', v_workplace_location.name,
            'distance_meters', round(v_distance_meters, 1),
            'validation_passed', v_gps_valid OR v_wifi_valid
        ),
        'shift_info', jsonb_build_object(
            'shift_name', v_current_shift.name,
            'start_time', v_current_shift.start_time,
            'end_time', v_current_shift.end_time
        ),
        'pre_approval', CASE 
            WHEN v_pre_approval IS NOT NULL THEN
                jsonb_build_object(
                    'type', v_pre_approval.request_type,
                    'reason', v_pre_approval.reason
                )
            ELSE null
        END,
        'risk_assessment', jsonb_build_object(
            'score', v_risk_score,
            'level', CASE 
                WHEN v_risk_score >= 80 THEN 'high'
                WHEN v_risk_score >= 40 THEN 'medium'  
                ELSE 'low'
            END
        )
    );

EXCEPTION 
    WHEN OTHERS THEN
        -- Log error và return safe response
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'SYSTEM_ERROR',
            'message', 'An unexpected error occurred. Please try again.',
            'debug_info', CASE 
                WHEN current_setting('app.debug_mode', true) = 'true' THEN
                    jsonb_build_object('error', SQLERRM)
                ELSE null
            END
        );
END;
$$;

-- ============================================================
-- PERMISSIONS FOR POSTGREST
-- ============================================================
-- Grant execute permission to mobile_user role (PostgREST anonymous role)
-- This allows the function to be exposed as RPC endpoint
GRANT EXECUTE ON FUNCTION mobile_api.attendance_checkin_checkout(TEXT, DECIMAL, DECIMAL, DECIMAL, TEXT, TEXT, JSONB) TO mobile_user;

-- Note: If you have authenticated role, grant to it as well
-- GRANT EXECUTE ON FUNCTION mobile_api.attendance_checkin_checkout(TEXT, DECIMAL, DECIMAL, DECIMAL, TEXT, TEXT, JSONB) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION mobile_api.attendance_checkin_checkout(TEXT, DECIMAL, DECIMAL, DECIMAL, TEXT, TEXT, JSONB) IS 
'Mobile attendance check-in/check-out với GPS và WiFi validation. 
Requires JWT authentication để lấy employee ID.
Supports pre-approvals, fraud detection, và full audit trail.';

-- Example usage:
-- POST /rpc/attendance_checkin_checkout
-- Content-Type: application/json
-- Authorization: Bearer <jwt_token>
-- X-Device-ID: <device_uuid>
-- X-Platform: android|ios
-- 
-- Body: {
--   "p_action": "check_in",
--   "p_latitude": 10.762622,
--   "p_longitude": 106.660172,
--   "p_gps_accuracy": 5.0,
--   "p_wifi_ssid": "Office-WiFi",
--   "p_wifi_bssid": "00:11:22:33:44:55",
--   "p_device_info": {
--     "device_id": "iPhone123",
--     "os": "iOS 17.0",
--     "app_version": "1.0.0"
--   }
-- } 