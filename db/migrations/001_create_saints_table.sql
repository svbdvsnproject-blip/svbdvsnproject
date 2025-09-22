-- Migration: 001_create_saints_table
-- Description: Creates saints table with date indexing and text description

-- UP
CREATE TABLE IF NOT EXISTS saints (
    id SERIAL PRIMARY KEY,
    memorial_date DATE NOT NULL,  -- Memorial date with fixed year 2000
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,    -- Can store very long text
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on memorial_date for efficient calendar lookups
CREATE INDEX idx_saints_memorial_date ON saints (memorial_date);

-- Create index on month and day components for specific lookups
CREATE INDEX idx_saints_month_day ON saints (EXTRACT(MONTH FROM memorial_date), EXTRACT(DAY FROM memorial_date));

-- Add GIN index for full text search on description
CREATE INDEX idx_saints_description_gin ON saints USING GIN (to_tsvector('spanish', description));

-- Add GIN index for name search
CREATE INDEX idx_saints_name_gin ON saints USING GIN (to_tsvector('spanish', name));

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_saints_updated_at
    BEFORE UPDATE ON saints
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comment on table and columns
COMMENT ON TABLE saints IS 'Table to store saints with optimized date indexing';
COMMENT ON COLUMN saints.memorial_date IS 'Memorial date with fixed year 2000';
COMMENT ON COLUMN saints.name IS 'Name of the saint';
COMMENT ON COLUMN saints.description IS 'Detailed description of the saint, supports very long text';

-- DOWN
DROP TRIGGER IF EXISTS update_saints_updated_at ON saints;
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP INDEX IF EXISTS idx_saints_description_gin;
DROP INDEX IF EXISTS idx_saints_name_gin;
DROP INDEX IF EXISTS idx_saints_month_day;
DROP INDEX IF EXISTS idx_saints_memorial_date;
DROP TABLE IF EXISTS saints;
