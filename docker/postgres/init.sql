-- Create the brimming schema for app tables
-- This runs on database initialization before Rails connects

CREATE SCHEMA IF NOT EXISTS brimming;

-- Grant usage to the brimming user
GRANT ALL ON SCHEMA brimming TO brimming;

-- Set default privileges so new tables are accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA brimming GRANT ALL ON TABLES TO brimming;
ALTER DEFAULT PRIVILEGES IN SCHEMA brimming GRANT ALL ON SEQUENCES TO brimming;
