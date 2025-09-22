-- UP ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS consolidated_saint (
    id          SERIAL PRIMARY KEY,
    name        TEXT    NOT NULL UNIQUE,         -- nombre único
    description TEXT    NOT NULL,                -- texto largo
    date        DATE    NOT NULL,                -- año fijo 2000-MM-DD
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_consolidated_saint_name
    ON consolidated_saint USING btree (name text_pattern_ops);

CREATE OR REPLACE FUNCTION trg_consolidated_saint_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_consolidated_saint_updated_at
    BEFORE UPDATE ON consolidated_saint
    FOR EACH ROW
    EXECUTE FUNCTION trg_consolidated_saint_set_updated_at();

COMMENT ON TABLE  consolidated_saint                IS 'Tabla consolidada: santo único + descripción + fecha 2000-MM-DD';
COMMENT ON COLUMN consolidated_saint.name           IS 'Nombre único del santo';
COMMENT ON COLUMN consolidated_saint.description    IS 'Descripción completa del santo';
COMMENT ON COLUMN consolidated_saint.date           IS 'Memorial en año 2000 para orden cronológico';

-- DOWN ────────────────────────────────────────────────────────────
DROP TRIGGER  IF EXISTS trg_consolidated_saint_updated_at  ON consolidated_saint;
DROP FUNCTION IF EXISTS trg_consolidated_saint_set_updated_at();
DROP INDEX    IF EXISTS idx_consolidated_saint_name;
DROP TABLE    IF EXISTS consolidated_saint;