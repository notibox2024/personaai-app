-- ============================================================
-- MOBILE API PERMISSIONS SETUP
-- ============================================================
-- Grant permissions for mobile_api schema functions to mobile_user role
-- This is required for PostgREST to expose functions as RPC endpoints
-- 
-- PostgREST Configuration:
-- PGRST_DB_SCHEMAS: mobile_api
-- PGRST_DB_ANON_ROLE: mobile_user
-- ============================================================

-- Ensure mobile_user role exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mobile_user') THEN
        CREATE ROLE mobile_user;
        RAISE NOTICE 'Created role mobile_user';
    ELSE
        RAISE NOTICE 'Role mobile_user already exists';
    END IF;
END
$$;

-- Grant usage on mobile_api schema
GRANT USAGE ON SCHEMA mobile_api TO mobile_user;

-- Grant execute on all existing functions in mobile_api schema
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA mobile_api TO mobile_user;

-- Grant execute on future functions in mobile_api schema
ALTER DEFAULT PRIVILEGES IN SCHEMA mobile_api GRANT EXECUTE ON FUNCTIONS TO mobile_user;

-- ============================================================
-- SPECIFIC FUNCTION PERMISSIONS
-- ============================================================

-- FCM Token Management
GRANT EXECUTE ON FUNCTION mobile_api.update_fcm_token(TEXT) TO mobile_user;

-- User Profile Functions
-- GRANT EXECUTE ON FUNCTION mobile_api.get_current_user_profile() TO mobile_user;

-- Weather Data Functions  
-- GRANT EXECUTE ON FUNCTION mobile_api.get_weather_data() TO mobile_user;

-- Other mobile API functions can be added here...

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check granted permissions
DO $$
DECLARE
    func_record RECORD;
    permission_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Checking mobile_api function permissions for mobile_user:';
    
    FOR func_record IN 
        SELECT 
            p.proname as function_name,
            pg_catalog.pg_get_function_arguments(p.oid) as arguments
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace  
        WHERE n.nspname = 'mobile_api'
        ORDER BY p.proname
    LOOP
        -- Check if mobile_user has execute permission
        IF has_function_privilege('mobile_user', 
            'mobile_api.' || func_record.function_name || '(' || func_record.arguments || ')', 
            'execute') THEN
            RAISE NOTICE '✅ mobile_user can execute: %(%)', func_record.function_name, func_record.arguments;
            permission_count := permission_count + 1;
        ELSE
            RAISE NOTICE '❌ mobile_user CANNOT execute: %(%)', func_record.function_name, func_record.arguments;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total functions with mobile_user execute permission: %', permission_count;
END
$$;

-- Show all mobile_api functions
SELECT 
    p.proname as function_name,
    pg_catalog.pg_get_function_arguments(p.oid) as arguments,
    obj_description(p.oid, 'pg_proc') as description
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace  
WHERE n.nspname = 'mobile_api'
ORDER BY p.proname; 