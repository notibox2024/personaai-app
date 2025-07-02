-- ============================================================
-- MOBILE API FUNCTION: update_fcm_token
-- ============================================================
-- Description: Cập nhật FCM token cho device của user hiện tại
-- Endpoint: POST /rpc/update_fcm_token
-- Parameters: fcm_token (string)
-- 
-- Features:
-- - Lấy employee_id từ JWT email
-- - Sử dụng device headers để lưu thông tin device
-- - UPSERT logic (insert or update)
-- - Deactivate old tokens cho cùng device
-- - Error handling và validation
-- ============================================================

CREATE OR REPLACE FUNCTION mobile_api.update_fcm_token(
    p_fcm_token TEXT
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    token_id BIGINT,
    employee_id INTEGER,
    device_id TEXT,
    platform TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_email TEXT;
    v_employee_id INTEGER;
    v_device_id TEXT;
    v_platform TEXT;
    v_device_name TEXT;
    v_device_model TEXT;
    v_os_version TEXT;
    v_app_version TEXT;
    v_user_agent TEXT;
    v_existing_token_id BIGINT;
    v_new_token_id BIGINT;
    v_error_message TEXT;
BEGIN
    -- Validate input
    IF p_fcm_token IS NULL OR LENGTH(TRIM(p_fcm_token)) = 0 THEN
        RETURN QUERY SELECT false, 'FCM token không được để trống'::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
        RETURN;
    END IF;
    
    IF LENGTH(p_fcm_token) > 500 THEN
        RETURN QUERY SELECT false, 'FCM token quá dài (max 500 ký tự)'::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
        RETURN;
    END IF;
    
    -- Get user email from JWT claims
    BEGIN
        v_user_email := current_setting('request.jwt.claims')::json->>'email';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT false, 'Không thể lấy thông tin email từ JWT token'::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
        RETURN;
    END;
    
    -- Validate email
    IF v_user_email IS NULL OR v_user_email = '' THEN
        RETURN QUERY SELECT false, 'Email không tồn tại trong JWT token'::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
        RETURN;
    END IF;
    
    -- Get employee_id from public.employees
    SELECT e.id INTO v_employee_id
    FROM public.employees e
    WHERE e.email_internal = v_user_email
      AND e.date_resign IS NULL; -- Only active employees
    
    IF v_employee_id IS NULL THEN
        RETURN QUERY SELECT false, ('Không tìm thấy nhân viên với email: ' || v_user_email)::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
        RETURN;
    END IF;
    
    -- Extract device information from HTTP headers
    BEGIN
        -- Get device ID (priority: X-Device-ID, X-Device-Identifier, generate from User-Agent)
        BEGIN
            v_device_id := current_setting('request.headers')::json->>'x-device-id';
        EXCEPTION WHEN OTHERS THEN
            v_device_id := NULL;
        END;
        
        IF v_device_id IS NULL OR v_device_id = '' THEN
            BEGIN
                v_device_id := current_setting('request.headers')::json->>'x-device-identifier';
            EXCEPTION WHEN OTHERS THEN
                v_device_id := NULL;
            END;
        END IF;
        
        -- If still no device ID, generate from User-Agent hash
        IF v_device_id IS NULL OR v_device_id = '' THEN
            BEGIN
                v_user_agent := current_setting('request.headers')::json->>'user-agent';
                IF v_user_agent IS NOT NULL THEN
                    v_device_id := 'ua_' || encode(digest(v_user_agent || v_employee_id::text, 'sha256'), 'hex')::text;
                    v_device_id := substring(v_device_id from 1 for 32); -- Limit length
                ELSE
                    v_device_id := 'unknown_' || extract(epoch from now())::bigint::text;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                v_device_id := 'fallback_' || extract(epoch from now())::bigint::text;
            END;
        END IF;
        
        -- Get platform (priority: X-Platform, X-Device-Platform, detect from User-Agent)
        BEGIN
            v_platform := current_setting('request.headers')::json->>'x-platform';
        EXCEPTION WHEN OTHERS THEN
            v_platform := NULL;
        END;
        
        IF v_platform IS NULL OR v_platform = '' THEN
            BEGIN
                v_platform := current_setting('request.headers')::json->>'x-device-platform';
            EXCEPTION WHEN OTHERS THEN
                v_platform := NULL;
            END;
        END IF;
        
        -- Detect platform from User-Agent if not provided
        IF v_platform IS NULL OR v_platform = '' THEN
            BEGIN
                v_user_agent := COALESCE(v_user_agent, current_setting('request.headers')::json->>'user-agent');
                IF v_user_agent IS NOT NULL THEN
                    v_user_agent := lower(v_user_agent);
                    IF v_user_agent LIKE '%iphone%' OR v_user_agent LIKE '%ipad%' OR v_user_agent LIKE '%ios%' THEN
                        v_platform := 'ios';
                    ELSIF v_user_agent LIKE '%android%' THEN
                        v_platform := 'android';
                    ELSIF v_user_agent LIKE '%flutter%' OR v_user_agent LIKE '%dart%' THEN
                        IF v_user_agent LIKE '%android%' THEN
                            v_platform := 'android';
                        ELSIF v_user_agent LIKE '%ios%' THEN
                            v_platform := 'ios';
                        ELSE
                            v_platform := 'mobile';
                        END IF;
                    ELSE
                        v_platform := 'unknown';
                    END IF;
                ELSE
                    v_platform := 'unknown';
                END IF;
            EXCEPTION WHEN OTHERS THEN
                v_platform := 'unknown';
            END;
        END IF;
        
        -- Get other device info from headers
        BEGIN
            v_device_name := current_setting('request.headers')::json->>'x-device-name';
        EXCEPTION WHEN OTHERS THEN
            v_device_name := NULL;
        END;
        
        BEGIN
            v_device_model := current_setting('request.headers')::json->>'x-device-model';
        EXCEPTION WHEN OTHERS THEN
            v_device_model := NULL;
        END;
        
        BEGIN
            v_os_version := current_setting('request.headers')::json->>'x-os-version';
        EXCEPTION WHEN OTHERS THEN
            v_os_version := NULL;
        END;
        
        BEGIN
            v_app_version := current_setting('request.headers')::json->>'x-app-version';
        EXCEPTION WHEN OTHERS THEN
            v_app_version := NULL;
        END;
        
    EXCEPTION WHEN OTHERS THEN
        -- If header parsing fails completely, use defaults
        v_device_id := 'error_' || extract(epoch from now())::bigint::text;
        v_platform := 'unknown';
        v_device_name := NULL;
        v_device_model := NULL;
        v_os_version := NULL;
        v_app_version := NULL;
    END;
    
    -- Ensure device_id is not too long
    v_device_id := substring(v_device_id from 1 for 200);
    v_platform := substring(v_platform from 1 for 20);
    v_device_name := substring(v_device_name from 1 for 100);
    v_device_model := substring(v_device_model from 1 for 100);
    v_os_version := substring(v_os_version from 1 for 50);
    v_app_version := substring(v_app_version from 1 for 20);
    
    -- Check if token already exists for this employee + device
    SELECT ft.id INTO v_existing_token_id
    FROM notification.fcm_tokens ft
    WHERE ft.employee_id = v_employee_id
      AND ft.device_id = v_device_id
    LIMIT 1;
    
    IF v_existing_token_id IS NOT NULL THEN
        -- Update existing token
        UPDATE notification.fcm_tokens
        SET 
            fcm_token = p_fcm_token,
            platform = v_platform,
            device_name = COALESCE(v_device_name, device_name),
            device_model = COALESCE(v_device_model, device_model),
            os_version = COALESCE(v_os_version, os_version),
            app_version = COALESCE(v_app_version, app_version),
            is_active = true,
            last_used_at = CURRENT_TIMESTAMP,
            error_count = 0, -- Reset error count on successful update
            last_error_message = NULL,
            last_modified_by = v_user_email,
            last_modified_date = CURRENT_TIMESTAMP
        WHERE id = v_existing_token_id;
        
        v_new_token_id := v_existing_token_id;
        
        -- Deactivate other tokens with same FCM token but different device
        UPDATE notification.fcm_tokens
        SET 
            is_active = false,
            last_modified_date = CURRENT_TIMESTAMP
        WHERE fcm_token = p_fcm_token
          AND id != v_existing_token_id
          AND is_active = true;
        
        RETURN QUERY SELECT 
            true, 
            'FCM token được cập nhật thành công'::TEXT, 
            v_new_token_id, 
            v_employee_id, 
            v_device_id, 
            v_platform;
    ELSE
        -- Insert new token
        INSERT INTO notification.fcm_tokens (
            employee_id,
            fcm_token,
            platform,
            device_id,
            device_name,
            device_model,
            os_version,
            app_version,
            is_active,
            last_used_at,
            error_count,
            last_error_message,
            created_by,
            created_date,
            last_modified_by,
            last_modified_date
        ) VALUES (
            v_employee_id,
            p_fcm_token,
            v_platform,
            v_device_id,
            v_device_name,
            v_device_model,
            v_os_version,
            v_app_version,
            true,
            CURRENT_TIMESTAMP,
            0,
            NULL,
            v_user_email,
            CURRENT_TIMESTAMP,
            v_user_email,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO v_new_token_id;
        
        -- Deactivate other tokens with same FCM token
        UPDATE notification.fcm_tokens
        SET 
            is_active = false,
            last_modified_date = CURRENT_TIMESTAMP
        WHERE fcm_token = p_fcm_token
          AND id != v_new_token_id
          AND is_active = true;
        
        RETURN QUERY SELECT 
            true, 
            'FCM token được tạo mới thành công'::TEXT, 
            v_new_token_id, 
            v_employee_id, 
            v_device_id, 
            v_platform;
    END IF;
    
EXCEPTION
    WHEN unique_violation THEN
        -- Handle unique constraint violation (should not happen with our logic, but just in case)
        RETURN QUERY SELECT false, 'Xung đột dữ liệu: Device đã tồn tại cho user này'::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
    WHEN OTHERS THEN
        -- Handle any other unexpected errors
        GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
        RETURN QUERY SELECT false, ('Lỗi hệ thống: ' || v_error_message)::TEXT, NULL::BIGINT, NULL::INTEGER, NULL::TEXT, NULL::TEXT;
END;
$$;

-- ============================================================
-- PERMISSIONS FOR POSTGREST
-- ============================================================
-- Grant execute permission to mobile_user role (PostgREST anonymous role)
-- This allows the function to be exposed as RPC endpoint
GRANT EXECUTE ON FUNCTION mobile_api.update_fcm_token(TEXT) TO mobile_user;

-- Note: If you have authenticated role, grant to it as well
-- GRANT EXECUTE ON FUNCTION mobile_api.update_fcm_token(TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION mobile_api.update_fcm_token(TEXT) IS 
'Cập nhật FCM token cho device của user hiện tại. 
Sử dụng JWT claims để lấy employee_id và HTTP headers để lấy device info.
Supports UPSERT operation và deactivate duplicate tokens.';

-- Example usage:
-- POST /rpc/update_fcm_token
-- Content-Type: application/json
-- Authorization: Bearer <jwt_token>
-- X-Device-ID: <device_uuid>
-- X-Platform: android|ios
-- X-Device-Name: <device_name>
-- X-Device-Model: <device_model>
-- X-OS-Version: <os_version>
-- X-App-Version: <app_version>
-- 
-- Body: {"p_fcm_token": "FCM_TOKEN_HERE"} 