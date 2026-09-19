# Harbor resolver contract

## Request

A request names a model object and optional dimensions or business filters. It never contains a tenant id, tenant slug, schema, or catalog.

```json
{
  "kind": "measure",
  "name": "occupancy",
  "dimensions": ["property.name"],
  "filters": []
}
```

`occupancy` is a business name. The Principal binding selects `official_occupied_units` or `live_occupied_units`; the measure definitions themselves contain no tenant conditionals.

## Principal

A Principal is trusted context created from authentication, not request input. It provides:

- the actor and surface (`embed` or `studio`);
- the tenant scope currently being viewed;
- the isolation method and value;
- permissions; and
- business bindings such as the meaning of `occupancy` and `open_jobs`.

There are two Principal factories:

- **Embed guest:** verifies Harbor's guest token and creates a Principal fixed to that token's tenant.
- **Studio:** verifies the Harbor employee's session and creates a Principal for the tenant context the employee is authorized to view.

Embed example: the request `{"kind":"measure","name":"occupancy"}` is paired with this Principal and resolves to `live_occupied_units`:

```yaml
actor: cedar_owner_guest
surface: embed
tenant_scope: cedar
isolation: { kind: schema }
bindings: { occupancy: live_occupied_units, open_jobs: not_yet_invoiced_jobs }
denied: [jobs.target_job_cost, target_job_cost]
```

Studio example: the same tenant-free request is paired with this Principal and resolves to `official_occupied_units`:

```yaml
actor: priya@harbor
surface: studio
tenant_scope: northline
isolation: { kind: row_filter, trusted_tenant: northline }
bindings: { occupancy: official_occupied_units, open_jobs: harbor_open_jobs }
denied: []
```

The Cedar target-cost restriction applies only to its embed Principal. An authorized Studio Principal may use that field.

## Isolation

- **Row filter:** the Principal supplies a trusted tenant. The resolver uses the model relationships to enforce that tenant on every applicable source; it does not assume every table has the same tenant column. This is how the SQLite seed represents both tenants.
- **Schema/catalog rewrite:** the Principal supplies an approved physical namespace mapping. The resolver rewrites model sources through that mapping; the request cannot name or override a schema or catalog. Cedar production uses this form.

Any tenant id, slug, schema, or catalog found in a request is rejected rather than treated as a normal filter.

## Checks before SQL

1. Build and authenticate the Principal. Reject an unknown actor or missing tenant scope.
2. Reject tenant or physical-namespace selectors in the request.
3. Resolve business names through the Principal's bindings.
4. Check access to every requested measure, field, dimension, filter, and verified query.
5. Apply the Principal's row filter or schema/catalog rewrite.
6. Validate that requested joins preserve each measure's grain. For example, in-place rent cannot traverse from units to leases.
7. Compile ordinary measures, or dispatch a verified query from the registry.

SQL runs only after all checks pass. Failures return an error and no query is executed.

## Errors

| Error | Meaning |
|---|---|
| `denied` | The Principal is valid, but it cannot access the requested object or field. |
| `isolated` | The request tries to choose another tenant or namespace, or the tenant boundary cannot be enforced safely. |
| `unauthorized` | The actor, session, guest token, or required tenant scope is not valid. |
| `grain` | A requested join or grouping would change a measure's defined grain and risk a wrong result. |

## Verified occupancy history

```json
{
  "kind": "verified_query",
  "name": "occupancy_over_time",
  "parameters": { "months": 12 }
}
```

The resolver authorizes the request, applies the Principal context, and retrieves `occupancy_over_time` from the verified-query registry in `model.yaml`. It does not generate a date spine or invent replacement SQL.
