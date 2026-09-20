-- Model object: official_occupied_units
-- Expected result: 29
-- Reporting period is supplied by trusted execution context, not by the plan.
SELECT occupancy_official.occupied_units AS result
FROM occupancy_official
JOIN tenants ON occupancy_official.tenant_id = tenants.id
WHERE tenants.slug = 'northline'
  AND occupancy_official.as_of = '2026-03-31';
