-- Minimal skema untuk prototype integrasi WhatsApp; evaluasi retensi data sebelum produksi.
CREATE TABLE IF NOT EXISTS conversations (
  phone TEXT PRIMARY KEY,
  mode TEXT NOT NULL DEFAULT 'ai' CHECK(mode IN ('ai','human')),
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  phone TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('customer','assistant','system')),
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'stored',
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE INDEX IF NOT EXISTS idx_messages_phone_created ON messages(phone, created_at DESC);

CREATE TABLE IF NOT EXISTS orders (
  order_id TEXT PRIMARY KEY,
  customer_phone TEXT NOT NULL,
  status TEXT NOT NULL,
  tracking_number TEXT,
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);
