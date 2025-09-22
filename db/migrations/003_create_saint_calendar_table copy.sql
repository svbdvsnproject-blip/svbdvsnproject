-- Migration: 003_create_saint_calendar_table
-- Description: Creates saint_calendar table with date indexing (day/month with fixed year 2000)

-- UP
CREATE TABLE IF NOT EXISTS saint_calendar (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,  -- Date with fixed year 2000
    name TEXT NOT NULL,  -- Can have multiple saints per date
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on date for efficient calendar lookups
CREATE INDEX idx_saint_calendar_date ON saint_calendar (date);

-- Create index on month and day components for specific lookups
CREATE INDEX idx_saint_calendar_month_day ON saint_calendar (EXTRACT(MONTH FROM date), EXTRACT(DAY FROM date));

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_saint_calendar_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_saint_calendar_updated_at
    BEFORE UPDATE ON saint_calendar
    FOR EACH ROW
    EXECUTE FUNCTION update_saint_calendar_updated_at_column();

-- Comment on table and columns
COMMENT ON TABLE saint_calendar IS 'Table to store saints calendar with optimized date indexing';
COMMENT ON COLUMN saint_calendar.date IS 'Date with fixed year 2000';
COMMENT ON COLUMN saint_calendar.name IS 'Name of the saint(s) for this date';

-- DOWN
DROP TRIGGER IF EXISTS update_saint_calendar_updated_at ON saint_calendar;
DROP FUNCTION IF EXISTS update_saint_calendar_updated_at_column();
DROP INDEX IF EXISTS idx_saint_calendar_month_day;
DROP INDEX IF EXISTS idx_saint_calendar_date;
DROP TABLE IF EXISTS saint_calendar;
