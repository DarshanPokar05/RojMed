-- ============================================================
-- ROJ MED — Supabase PostgreSQL Schema
-- Run this in Supabase → SQL Editor → New Query → Run
-- ============================================================

-- ── 1. daily_entries ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_entries (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_date        DATE        NOT NULL UNIQUE,
  opening_balance   NUMERIC(12,2) NOT NULL DEFAULT 0,
  daily_collection  NUMERIC(12,2) NOT NULL DEFAULT 0,  -- manually entered by user
  shop_total        NUMERIC(12,2) NOT NULL DEFAULT 0,  -- auto-summed in Flutter
  personal_total    NUMERIC(12,2) NOT NULL DEFAULT 0,  -- auto-summed in Flutter
  closing_balance   NUMERIC(12,2) NOT NULL DEFAULT 0,  -- opening + (collection - shop - personal)
  corner_number     INTEGER       NOT NULL DEFAULT 0,  -- ceil(daily_collection / 1000) * 10
  notes             TEXT,
  synced_at         TIMESTAMPTZ   DEFAULT NOW(),
  created_at        TIMESTAMPTZ   DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_entries_date
  ON daily_entries(entry_date DESC);

-- ── 2. entry_items ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS entry_items (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_entry_id   UUID          NOT NULL REFERENCES daily_entries(id) ON DELETE CASCADE,
  type             TEXT          NOT NULL CHECK (type IN ('shop', 'personal')),
  label            TEXT          NOT NULL,
  amount           NUMERIC(12,2) NOT NULL DEFAULT 0,
  sort_order       INTEGER       DEFAULT 0,
  created_at       TIMESTAMPTZ   DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_entry_items_entry
  ON entry_items(daily_entry_id);

-- ── 3. app_settings ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS app_settings (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL DEFAULT ''
);

INSERT INTO app_settings (key, value) VALUES
  ('registered_email', ''),
  ('pin_hash', '')
ON CONFLICT (key) DO NOTHING;

-- ── 4. Row Level Security ────────────────────────────────────
ALTER TABLE daily_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE entry_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings  ENABLE ROW LEVEL SECURITY;

-- Single-user app: allow all operations (no user auth required)
CREATE POLICY "allow_all_daily_entries" ON daily_entries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_entry_items"   ON entry_items   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_app_settings"  ON app_settings  FOR ALL USING (true) WITH CHECK (true);

-- ── 5. Realtime (enable for live sync) ───────────────────────
-- Run in Supabase Dashboard → Database → Replication → enable for:
--   daily_entries, entry_items
