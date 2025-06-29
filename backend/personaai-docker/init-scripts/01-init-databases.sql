-- Create keycloak database if it doesn't exist
SELECT 'CREATE DATABASE keycloak'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak')\gexec

-- Connect to personaai database for PostgREST setup
\c personaai;

-- Create roles for PostgREST
DO $$
BEGIN
  -- Anonymous role for unauthenticated requests
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
  
  -- Authenticated user role
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  
  -- API schema owner role
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'api_owner') THEN
    CREATE ROLE api_owner NOLOGIN;
  END IF;
END
$$;

-- Grant basic permissions
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO web_anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;

-- Create API schema for PostgREST
CREATE SCHEMA IF NOT EXISTS api AUTHORIZATION api_owner;

-- Grant permissions on API schema
GRANT USAGE ON SCHEMA api TO web_anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA api TO web_anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA api TO authenticated;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES FOR ROLE api_owner IN SCHEMA api 
GRANT SELECT ON TABLES TO web_anon;

ALTER DEFAULT PRIVILEGES FOR ROLE api_owner IN SCHEMA api 
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

-- Create a sample function to verify JWT tokens
CREATE OR REPLACE FUNCTION api.verify_jwt()
RETURNS json
LANGUAGE sql
STABLE
AS $$
  SELECT current_setting('request.jwt.claims', true)::json;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION api.verify_jwt() TO web_anon, authenticated; 