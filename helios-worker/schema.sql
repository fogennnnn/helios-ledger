-- Helios Ledger v5.2 — D1 Schema
-- Run: npx wrangler d1 execute helios-ledger --file=schema.sql

CREATE TABLE IF NOT EXISTS accounts (
  id            TEXT PRIMARY KEY,
  username      TEXT UNIQUE NOT NULL,
  public_key    TEXT,
  token_hash    TEXT NOT NULL,
  balance       INTEGER DEFAULT 0,
  created_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS records (
  id            TEXT PRIMARY KEY,
  content_hash  TEXT NOT NULL,
  signature     TEXT NOT NULL,
  model         TEXT,
  context       TEXT,
  account_id    TEXT,
  merkle_index  INTEGER NOT NULL,
  timestamp     TEXT NOT NULL,
  source_node   TEXT
);

CREATE TABLE IF NOT EXISTS merkle_tree (
  level   INTEGER NOT NULL,
  pos     INTEGER NOT NULL,
  hash    TEXT NOT NULL,
  PRIMARY KEY (level, pos)
);

CREATE TABLE IF NOT EXISTS merkle_nodes (
  idx   INTEGER PRIMARY KEY,
  hash  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ledger_meta (
  key   TEXT PRIMARY KEY,
  value TEXT
);

CREATE TABLE IF NOT EXISTS rate_limits (
  key           TEXT PRIMARY KEY,
  count         INTEGER DEFAULT 0,
  window_start  TEXT
);

CREATE TABLE IF NOT EXISTS seen_nonces (
  nonce TEXT PRIMARY KEY
);

-- Seed initial metadata
INSERT OR IGNORE INTO ledger_meta (key, value) VALUES ('record_count', '0');
INSERT OR IGNORE INTO ledger_meta (key, value) VALUES ('root', '');

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_records_content_hash ON records (content_hash);
CREATE INDEX IF NOT EXISTS idx_records_merkle_index ON records (merkle_index);
CREATE INDEX IF NOT EXISTS idx_records_account_id ON records (account_id);
CREATE INDEX IF NOT EXISTS idx_accounts_token_hash ON accounts (token_hash);
CREATE INDEX IF NOT EXISTS idx_accounts_username ON accounts (username);
