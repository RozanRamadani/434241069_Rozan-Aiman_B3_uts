-- Menambahkan kolom-kolom untuk fitur Stepping Wizard
ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS assigned_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS processed_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS resolved_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS cancelled_at timestamptz NULL;
