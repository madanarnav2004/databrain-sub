-- Numbers are small on purpose. Wrong grain and missing filters are round, obvious misses.

INSERT INTO tenants (id, slug, name) VALUES
  (1, 'northline', 'Northline Properties'),
  (2, 'cedar', 'Cedar Court');

-- Northline: Tower is fully active. Annex fails property.active (open-jobs trap).
INSERT INTO properties (id, tenant_id, name, is_active, active) VALUES
  (1, 1, 'Harbor Tower', 1, 1),
  (2, 1, 'Annex', 1, 0),
  (3, 2, 'Cedar Court', 1, 1);

-- Northline rentable: 100 + 200 = 300 in-place rent. Common Area +50 if you forget the noun.
INSERT INTO units (id, property_id, name, status, market_rent, is_common_area) VALUES
  (1, 1, '1A', 'occupied', 100, 0),
  (2, 1, '1B', 'occupied', 200, 0),
  (3, 1, 'Common Area', 'occupied', 50, 1),
  (4, 3, '2A', 'occupied', 50, 0),
  (5, 3, '2B', 'occupied', 70, 0),
  (6, 3, '2C', 'vacant', 80, 0);

-- Two leases per rentable unit (CURRENT + HISTORICAL). Join units ⨯ leases and SUM(market_rent)
-- → Northline 600, Cedar 400.
INSERT INTO leases (id, unit_id, type, start_date) VALUES
  (1, 1, 'HISTORICAL', '2024-01-01'),
  (2, 1, 'CURRENT', '2025-01-01'),
  (3, 2, 'HISTORICAL', '2024-01-01'),
  (4, 2, 'CURRENT', '2025-06-01'),
  (5, 4, 'HISTORICAL', '2024-01-01'),
  (6, 4, 'CURRENT', '2025-01-01'),
  (7, 5, 'HISTORICAL', '2024-01-01'),
  (8, 5, 'CURRENT', '2025-03-01'),
  (9, 6, 'HISTORICAL', '2024-01-01'),
  (10, 6, 'CURRENT', '2025-09-01');

-- Official pack is the whole portfolio. Extract is two buildings. Northline will not let you "fix" 29.
INSERT INTO occupancy_official (id, tenant_id, as_of, occupied_units, notes) VALUES
  (1, 1, '2026-03-31', 29, 'Admin pack. Ops signs this. Extract occupied count is 2 — they do not care.'),
  (2, 2, '2026-03-31', 3, 'Lagged. Cedar reports live occupied rentable units (2), not this.');

-- Open jobs (Northline, full bundle) = j1 + j2 only.
-- j6 is Open/Active on Annex (property.active = 0). Counting it (3) is the product bug.
INSERT INTO jobs (id, property_id, stage, job_status, is_active, target_job_cost) VALUES
  (1, 1, 'Open', 'Active', 1, 40),
  (2, 1, 'Scheduled', 'Active', 1, 40),
  (3, 1, 'Closed', 'Active', 1, 10),
  (4, 1, 'Open', 'Rejected', 1, 10),
  (5, 1, 'Open', 'Active', 0, 10),
  (6, 2, 'Open', 'Active', 1, 25),
  (7, 3, 'Open', 'Active', 1, 90),
  (8, 3, 'Open', 'Active', 1, 90);

-- Approved invoice spend uses cost.total. Never jobs.target_job_cost.
INSERT INTO job_costs (id, job_id, type, status, total) VALUES
  (1, 1, 'Invoice', 'Approved', 30),
  (2, 7, 'Invoice', 'Approved', 40),
  (3, 8, 'Estimate', 'Draft', 90);

