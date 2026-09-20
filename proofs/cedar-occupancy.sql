SELECT COUNT(units.id) AS result
FROM units
JOIN properties ON units.property_id = properties.id
JOIN tenants ON properties.tenant_id = tenants.id
WHERE units.status = 'occupied'
  AND units.is_common_area = 0
  AND tenants.slug = 'cedar';
