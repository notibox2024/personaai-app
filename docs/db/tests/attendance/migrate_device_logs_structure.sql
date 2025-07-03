-- =============================================================================
-- MIGRATION: Add dedicated columns to device_logs table
-- Purpose: Thêm các columns chuyên dụng thay vì dùng JSONB để dễ query và hiển thị
-- =============================================================================

-- Backup existing data first (optional)
-- CREATE TABLE attendance.device_logs_backup AS SELECT * FROM attendance.device_logs;

-- Add new columns to device_logs table
ALTER TABLE attendance.device_logs 
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8),
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8),
ADD COLUMN IF NOT EXISTS gps_accuracy DECIMAL(6,2),
ADD COLUMN IF NOT EXISTS wifi_ssid TEXT,
ADD COLUMN IF NOT EXISTS wifi_bssid TEXT,
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'app',
ADD COLUMN IF NOT EXISTS action TEXT,
ADD COLUMN IF NOT EXISTS session_id UUID;

-- Migrate existing data from JSONB to dedicated columns (if any)
UPDATE attendance.device_logs 
SET 
    latitude = (location_data->>'latitude')::DECIMAL(10,8),
    longitude = (location_data->>'longitude')::DECIMAL(11,8),
    gps_accuracy = (location_data->>'accuracy')::DECIMAL(6,2),
    wifi_ssid = location_data->>'wifi_ssid',
    wifi_bssid = location_data->>'wifi_bssid',
    action = action_type,
    source = COALESCE(device_info->>'source', 'app')
WHERE location_data IS NOT NULL;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_device_logs_employee_date 
ON attendance.device_logs(employee_id, created_at);

CREATE INDEX IF NOT EXISTS idx_device_logs_location 
ON attendance.device_logs(latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_device_logs_session 
ON attendance.device_logs(session_id) 
WHERE session_id IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN attendance.device_logs.latitude IS 'GPS latitude coordinate';
COMMENT ON COLUMN attendance.device_logs.longitude IS 'GPS longitude coordinate';  
COMMENT ON COLUMN attendance.device_logs.gps_accuracy IS 'GPS accuracy in meters';
COMMENT ON COLUMN attendance.device_logs.wifi_ssid IS 'WiFi network SSID';
COMMENT ON COLUMN attendance.device_logs.wifi_bssid IS 'WiFi network BSSID/MAC address';
COMMENT ON COLUMN attendance.device_logs.source IS 'Data source: app, web, api, etc';
COMMENT ON COLUMN attendance.device_logs.action IS 'Action type: check_in, check_out, etc';
COMMENT ON COLUMN attendance.device_logs.session_id IS 'Reference to attendance session';

-- Show table structure after migration
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'attendance' 
    AND table_name = 'device_logs'
ORDER BY ordinal_position;

-- Summary
SELECT 
    'DEVICE_LOGS MIGRATION COMPLETED' as status,
    'Added dedicated columns for location and WiFi data' as message; 