#!/bin/bash

set -e
set -u

function create_user_and_database() {
	local database=$1
	echo "Checking and creating database '$database' if it doesn't exist..."
	
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
		-- Create database only if it doesn't exist
		SELECT 'CREATE DATABASE $database'
		WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$database')\gexec
		
		-- Grant privileges on the database (this is safe to run multiple times)
		\c $database
		GRANT ALL PRIVILEGES ON DATABASE $database TO $POSTGRES_USER;
		
		-- Switch back to default database
		\c $POSTGRES_DB
EOSQL
	
	echo "Database '$database' is ready"
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
		create_user_and_database $db
	done
	echo "All databases are ready"
fi 