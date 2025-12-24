-- Initialization script for PostgreSQL databases
-- This script creates the databases that your applications need
-- Run this after PostgreSQL is initialized

-- Create hostly database (if it doesn't exist)
SELECT 'CREATE DATABASE hostly'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hostly')\gexec

-- Create laravel database (if it doesn't exist) - for backend
SELECT 'CREATE DATABASE laravel'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'laravel')\gexec

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON DATABASE hostly TO hostly_user;
GRANT ALL PRIVILEGES ON DATABASE laravel TO hostly_user;

-- List all databases
\l

