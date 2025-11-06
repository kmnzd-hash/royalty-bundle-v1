BEGIN;

CREATE TABLE IF NOT EXISTS treasury_reports (
  report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  report_type TEXT CHECK (report_type IN ('monthly','quarterly')) NOT NULL,
  total_royalties NUMERIC(14,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

COMMIT;