-- Harbor warehouse (SQLite)
-- Two Harbor tenants in one physical DB so the take-home stays one file.
-- In production Cedar is schema-per-tenant. Isolation is still the Principal's
-- job — do not treat tenant_id in a plan as the access control.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS job_costs;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS occupancy_official;
DROP TABLE IF EXISTS leases;
DROP TABLE IF EXISTS units;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS tenants;

CREATE TABLE tenants (
  id INTEGER PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL
);

CREATE TABLE properties (
  id INTEGER PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants (id),
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL,   -- Harbor flag 1
  active INTEGER NOT NULL       -- Harbor flag 2. Both required for "open jobs."
);

CREATE TABLE units (
  id INTEGER PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties (id),
  name TEXT NOT NULL,
  status TEXT NOT NULL,         -- occupied | vacant
  market_rent INTEGER NOT NULL,
  is_common_area INTEGER NOT NULL
);

CREATE TABLE leases (
  id INTEGER PRIMARY KEY,
  unit_id INTEGER NOT NULL REFERENCES units (id),
  type TEXT NOT NULL,           -- CURRENT | HISTORICAL
  start_date TEXT NOT NULL
);

CREATE TABLE occupancy_official (
  id INTEGER PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants (id),
  as_of TEXT NOT NULL,
  occupied_units INTEGER NOT NULL,
  notes TEXT
);

CREATE TABLE jobs (
  id INTEGER PRIMARY KEY,
  property_id INTEGER NOT NULL REFERENCES properties (id),
  stage TEXT NOT NULL,          -- Open | Scheduled | Cancelled | Closed
  job_status TEXT NOT NULL,     -- Active | Rejected
  is_active INTEGER NOT NULL,
  target_job_cost INTEGER NOT NULL  -- estimate. Not approved spend. Cedar guest: deny.
);

CREATE TABLE job_costs (
  id INTEGER PRIMARY KEY,
  job_id INTEGER NOT NULL REFERENCES jobs (id),
  type TEXT NOT NULL,           -- Invoice | Estimate
  status TEXT NOT NULL,         -- Approved | Draft
  total INTEGER NOT NULL
);

