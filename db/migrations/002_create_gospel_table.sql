-- Migration: 001_create_saints_table
-- Description: Creates gospel table with date indexing and text description

-- UP
CREATE TABLE IF NOT EXISTS gospel (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on date for efficient calendar lookups
CREATE INDEX idx_gospel_date ON gospel (date);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_gospel_updated_at
    BEFORE UPDATE ON gospel
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comment on table and columns
COMMENT ON TABLE gospel IS 'Table to store gospel with date indexing';
COMMENT ON COLUMN gospel.date IS 'Date of the gospel';
COMMENT ON COLUMN gospel.name IS 'Name of the gospel';
COMMENT ON COLUMN gospel.description IS 'Detailed description of the gospel, supports very long text';

-- Down Migration
-- Down migration is wrapped in a transaction
-- DROP TRIGGER IF EXISTS update_gospel_updated_at ON gospel;
-- DROP FUNCTION IF EXISTS update_updated_at_column();
-- DROP INDEX IF EXISTS idx_gospel_date;
-- DROP TABLE IF EXISTS gospel;
