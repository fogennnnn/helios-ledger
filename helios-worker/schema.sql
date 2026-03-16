-- Helios Ledger D1 Schema
-- Apply with: npx wrangler d1 execute helios-ledger --file=schema.sql

CREATE TABLE IF NOT EXISTS accounts (
  id          TEXT PRIMARY KEY,
  username    TEXT UNIQUE NOT NULL,
  public_key  TEXT,
  token_hash  TEXT UNIQUE NOT NULL,
  balance     INTEGER DEFAULT 0,
  created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS records (
  id            TEXT PRIMARY KEY,
  content_hash  TEXT NOT NULL,
  signature     TEXT NOT NULL,
  model         TEXT,
  context       TEXT,
  account_id    TEXT,
  merkle_index  INTEGER,
  timestamp     TEXT NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts(id)
);

CREATE TABLE IF NOT EXISTS merkle_nodes (
  idx   INTEGER PRIMARY KEY,
  hash  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ledger_meta (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT OR IGNORE INTO ledger_meta (key, value) VALUES ('root', '0000000000000000000000000000000000000000000000000000000000000000');
INSERT OR IGNORE INTO ledger_meta (key, value) VALUES ('record_count', '0');

CREATE TABLE IF NOT EXISTS rate_limits (
  key          TEXT PRIMARY KEY,
  count        INTEGER DEFAULT 0,
  window_start INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_window ON rate_limits(window_start);
