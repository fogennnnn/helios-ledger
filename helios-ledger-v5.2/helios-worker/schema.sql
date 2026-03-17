-- Helios Ledger D1 Schema v5.2
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
  source_node   TEXT,
  FOREIGN KEY (account_id) REFERENCES accounts(id)
);

-- Legacy flat leaf table (kept for migration compatibility)
CREATE TABLE IF NOT EXISTS merkle_nodes (
  idx   INTEGER PRIMARY KEY,
  hash  TEXT NOT NULL
);

-- Incremental Merkle tree: O(log n) insert/proof/root
-- level 0 = leaves, level H = root
CREATE TABLE IF NOT EXISTS merkle_tree (
  level INTEGER NOT NULL,
  pos   INTEGER NOT NULL,
  hash  TEXT NOT NULL,
  PRIMARY KEY (level, pos)
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
CREATE INDEX IF NOT EXISTS idx_records_content_hash ON records(content_hash);
CREATE INDEX IF NOT EXISTS idx_records_merkle_index ON records(merkle_index);
