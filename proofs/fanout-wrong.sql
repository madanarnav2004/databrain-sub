-- Intentional bug demonstration for model object: in_place_rent
-- Expected incorrect result: 600; a real plan must fail with grain
SELECT SUM(units.market_rent) AS result
FROM units
JOIN leases ON leases.unit_id = units.id
JOIN properties ON units.property_id = properties.id
JOIN tenants ON properties.tenant_id = tenants.id
WHERE units.is_common_area = 0
  AND tenants.slug = 'northline';
