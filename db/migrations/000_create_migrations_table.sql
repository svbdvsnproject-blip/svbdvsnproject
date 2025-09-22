-- Migration: 000_create_migrations_table
-- Description: Create migrations tracking table
-- Created: 2025-07-05

-- UP
CREATE TABLE IF NOT EXISTS migrations (
  id SERIAL PRIMARY KEY,
  version VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  rollback_at TIMESTAMP NULL,
  status VARCHAR(20) DEFAULT 'executed' CHECK (status IN ('executed', 'rolled_back'))
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_migrations_version ON migrations(version);
CREATE INDEX IF NOT EXISTS idx_migrations_status ON migrations(status);

-- DOWN
DROP INDEX IF EXISTS idx_migrations_status;
DROP INDEX IF EXISTS idx_migrations_version;
DROP TABLE IF EXISTS migrations;
