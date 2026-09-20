SELECT COUNT(jobs.id) AS result
FROM jobs
JOIN properties ON jobs.property_id = properties.id
JOIN tenants ON properties.tenant_id = tenants.id
WHERE jobs.stage NOT IN ('Cancelled', 'Closed')
  AND jobs.job_status <> 'Rejected'
  AND jobs.is_active = 1
  AND properties.is_active = 1
  AND properties.active = 1
  AND tenants.slug = 'northline';
