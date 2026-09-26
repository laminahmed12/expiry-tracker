CREATE TABLE IF NOT EXISTS licenses (
 id TEXT PRIMARY KEY,
 customer_name TEXT NOT NULL,
 license_code_hash TEXT NOT NULL UNIQUE,
 plan TEXT NOT NULL CHECK(plan IN ('6_months','1_year','permanent')),
 device_id TEXT,
 issued_at TEXT NOT NULL,
 activated_at TEXT,
 expires_at TEXT,
 status TEXT NOT NULL DEFAULT 'active',
 last_check_at TEXT,
 created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_licenses_device ON licenses(device_id);
CREATE INDEX IF NOT EXISTS idx_licenses_status ON licenses(status);

CREATE TABLE IF NOT EXISTS audit_logs (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 action TEXT NOT NULL,
 license_id TEXT,
 device_id TEXT,
 details TEXT,
 created_at TEXT NOT NULL
);