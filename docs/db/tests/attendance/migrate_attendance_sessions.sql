-- =============================================================================
-- MIGRATION: Add missing columns to attendance_sessions table
-- Purpose: Thêm các columns cần thiết cho attendance function
-- =============================================================================

-- Add missing columns to attendance_sessions table
ALTER TABLE attendance.attendance_sessions 
ADD COLUMN IF NOT EXISTS shift_id INTEGER,
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active',
ADD COLUMN IF NOT EXISTS is_pre_approved BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS work_duration_minutes INTEGER;

-- Add foreign key constraint to work_shifts (if exists)
-- ALTER TABLE attendance.attendance_sessions 
-- ADD CONSTRAINT fk_attendance_sessions_shift 
-- FOREIGN KEY (shift_id) REFERENCES attendance.work_shifts(id);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_employee_date 
ON attendance.attendance_sessions(employee_id, work_date);

CREATE INDEX IF NOT EXISTS idx_attendance_sessions_status 
ON attendance.attendance_sessions(status) 
WHERE status IS NOT NULL;

-- Add comments
COMMENT ON COLUMN attendance.attendance_sessions.shift_id IS 'Reference to work_shifts table';
COMMENT ON COLUMN attendance.attendance_sessions.status IS 'Session status: active, completed, cancelled';
COMMENT ON COLUMN attendance.attendance_sessions.is_pre_approved IS 'Whether this session was pre-approved';
COMMENT ON COLUMN attendance.attendance_sessions.work_duration_minutes IS 'Calculated work duration in minutes';

-- Show updated structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'attendance' 
    AND table_name = 'attendance_sessions'
ORDER BY ordinal_position;

-- Summary
SELECT 
    'ATTENDANCE_SESSIONS MIGRATION COMPLETED' as status,
    'Added shift_id, status, is_pre_approved, work_duration_minutes columns' as message; 