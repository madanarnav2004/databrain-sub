SELECT occupancy_official.occupied_units AS result
FROM occupancy_official
JOIN tenants ON occupancy_official.tenant_id = tenants.id
WHERE tenants.slug = 'northline'
ORDER BY occupancy_official.as_of DESC
LIMIT 1;
