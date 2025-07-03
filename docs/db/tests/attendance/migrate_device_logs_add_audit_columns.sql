-- =================================================================
-- MIGRATION: Add audit columns to device_logs table
-- =================================================================

-- Add audit columns to device_logs
ALTER TABLE attendance.device_logs 
ADD COLUMN IF NOT EXISTS created_by TEXT DEFAULT 'system',
ADD COLUMN IF NOT EXISTS last_modified_by TEXT DEFAULT 'system',
ADD COLUMN IF NOT EXISTS last_modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Update existing records
UPDATE attendance.device_logs 
SET 
    created_by = 'system',
    last_modified_by = 'system',
    last_modified_at = COALESCE(created_at, CURRENT_TIMESTAMP)
WHERE created_by IS NULL OR last_modified_by IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN attendance.device_logs.created_by IS 'User or system that created this record';
COMMENT ON COLUMN attendance.device_logs.last_modified_by IS 'User or system that last modified this record';
COMMENT ON COLUMN attendance.device_logs.last_modified_at IS 'Timestamp when record was last modified';

-- Add index for audit queries
CREATE INDEX IF NOT EXISTS idx_device_logs_audit 
ON attendance.device_logs(created_by, last_modified_by, last_modified_at);

-- Verification
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_schema = 'attendance' 
    AND table_name = 'device_logs' 
    AND column_name IN ('created_by', 'last_modified_by', 'last_modified_at', 'created_at')
ORDER BY ordinal_position; 