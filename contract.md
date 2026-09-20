# Harbor resolver contract

## Authority and scope

This contract defines the trust boundary and fail-closed behavior for resolving Harbor analytics requests. It is normative for both Studio and the embedded product.

The locked `taxonomy.md` is the authority for business meaning. The locked `model.yaml` is the authority for entities, relationships, measures, semantic bindings, Principal construction, isolation, access, and verified-query dispatch. The runtime may implement those declarations; it may not replace them with tenant-specific logic.

The central rule is:

> Execute SQL only when tenant isolation, authorization, semantic definition, and calculation safety have all been proven. Otherwise return an explicit error and execute no SQL.

## Trust boundary

The user is trusted to state only the business intent, such as “show me occupancy.” Request content is never trusted as evidence of identity, tenant scope, permission, physical namespace, metric definition, or safe query shape.

Authentication creates a **Principal**, which is trusted execution context. A Principal supplies:

- the authenticated actor and surface (`embed` or `studio`);
- the one tenant scope the actor is authorized to view;
- the approved row-filter or schema/catalog isolation strategy;
- permissions;
- the tenant's assigned semantic profile and business bindings; and
- any other trusted execution values required by a measure, such as the reporting period for an official snapshot.

The request cannot create, amend, or override any of that context. All request fields remain untrusted and must be validated before planning.

## Request contract

A request names a logical model object and may include supported business dimensions, business filters, or declared parameters. It uses logical names only.

```json
{
  "kind": "measure",
  "name": "occupancy",
  "dimensions": [],
  "filters": []
}
```

A request must not contain a tenant selector or physical namespace selector anywhere in its payload. The forbidden selectors declared by the model are:

- `tenant`
- `tenant_id`
- `tenant_slug`
- `schema`
- `catalog`
- `database`

Supplying one is an attempted scope override. The resolver returns `isolated`; it does not ignore the selector, reinterpret it as a business filter, or run SQL.

## Principal construction

The runtime constructs the Principal before resolving the request:

- **Embed:** verify the Harbor guest token, derive tenant scope from that token, and load the tenant's assigned semantic profile.
- **Studio:** verify the Harbor employee session, verify the selected tenant context is authorized for that employee, and load that tenant's assigned semantic profile.

An unknown actor, invalid session or token, missing tenant scope, or unresolved required binding returns `unauthorized`. No warehouse SQL runs.

Studio is another surface over the same Harbor model, not another tenant and not a separate semantic implementation.

## Semantic resolution

Business names are stable. Their implementation is selected from the Principal's data-driven semantic profile:

| Business request | Northline binding | Cedar binding |
|---|---|---|
| `occupancy` | `official_occupied_units` | `live_occupied_units` |
| `open_jobs` | `harbor_open_jobs` | `not_yet_invoiced_jobs` |

For Northline, occupancy is the signed value in `occupancy_official` for the exact trusted reporting period. It is not reconstructed from the partial unit extract. If exactly one signed row is not available, the result is `unavailable`; there is no prior-period or unit-derived fallback.

For Cedar, occupancy is the current count of rentable units whose status is `occupied`. Common Area is excluded.

The runtime must not contain tenant branches such as `if tenant == "northline"`. It loads `tenant_profile_assignments`, resolves the business name through the assigned profile, and verifies that the resolved measure is one of the business metric's allowed implementations.

The same business name and tenant semantic profile must resolve to the same measure in Studio and embed. An explicit surface-specific access rule may still deny execution.

## Isolation

Tenant scope always comes from the Principal and must be enforceable for every source used by a plan.

- **Row filter:** start at the trusted Principal tenant and apply the model-declared `entity.tenant_scope` relationship path. Do not assume every entity carries a tenant column.
- **Schema/catalog rewrite:** resolve logical model sources through the Principal's approved namespace map. A plan contains logical sources only.

Only relationships listed in `model.yaml` may be planned. Missing scope returns `unauthorized`. A request scope override, a source with no provable path to the Principal tenant, or an unenforceable namespace boundary returns `isolated`. These failures execute no SQL.

## Authorization

Access is deny by default, and an explicit deny takes precedence over an allow. The resolver checks every requested or transitively required measure, field, dimension, filter, relationship, and verified query.

An inaccessible object returns `denied`. It must not be hidden, dropped from the result, replaced with `null`, or returned as zero.

In particular, a Cedar embed Principal cannot access `jobs.target_job_cost` or `target_job_cost`. The model separately declares an allow for a Studio Principal carrying `view_job_estimates`; the Studio surface alone is not itself an access rule.

## Calculation and grain safety

Each measure is calculated only from its declared entity, aggregate, field, filters, and allowed relationships. The resolver must preserve its declared grain.

- `in_place_rent` sums `units.market_rent` once per rentable unit. Vacant rentable units remain included and Common Area is excluded. A units-to-leases fanout is forbidden.
- `live_occupancy_rate` is `safe_divide(live_occupied_units, rentable_units)`; a zero denominator produces `null` as declared by the measure.
- `official_occupied_units` stays at tenant-reporting-period grain and cannot be grouped by property, unit, or lease.
- Reverse relationship traversal is allowed only when the measure explicitly allowlists it. Unlisted relationships are never inferred.

If a join, grouping, or traversal could change the declared grain or double-count a measure, the resolver returns `grain` and executes no SQL. It must not attempt to repair an unsafe plan with an unproven `DISTINCT`, deduplication, or alternate join.

## Verified occupancy history

Historical occupancy is a Class C operation, not generated SQL:

```json
{
  "kind": "verified_query",
  "name": "occupancy_over_time",
  "parameters": { "months": 12 }
}
```

After the normal Principal, isolation, access, and parameter checks, the resolver retrieves registry key `harbor.occupancy_over_time`. The registered query receives tenant scope from the Principal and uses the Principal's `occupancy` semantic binding.

`months` defaults to 12 and must be an integer from 1 through 60. The runtime must not invent a date spine, compose replacement history SQL, or silently switch occupancy definitions. A missing registry entry returns `unavailable` and executes no SQL.

## Mandatory pre-execution gate

The resolver performs these checks in order before any warehouse call:

1. Authenticate the actor and construct a complete Principal.
2. Reject request-supplied tenant or namespace selectors.
3. Resolve the requested logical object and business binding from the Principal's semantic profile.
4. Authorize every requested and required object, including verified queries.
5. Prove tenant isolation for every source in the plan.
6. Prove that every relationship, grouping, filter, and aggregate preserves the declared measure grain.
7. Either compile the declared ordinary measure or retrieve the declared verified query.

SQL execution is permitted only after all seven checks succeed. A failure is terminal for the request: return one explicit error, return no data rows, and make no warehouse call. The resolver must not run a partial plan to see what happens.

## Failure contract

| Error | Required meaning |
|---|---|
| `unauthorized` | Authentication, required tenant scope, or a required semantic binding is missing or invalid. |
| `isolated` | The request attempts to choose scope, or the resolver cannot prove the tenant boundary for the complete plan. |
| `denied` | The Principal is valid but lacks access to a requested or required object. |
| `grain` | The requested query shape can change the declared measure grain or produce an unsafe calculation. |
| `unavailable` | A required trusted value or approved registered query is absent; no allowed fallback exists. |

Errors are observable product outcomes, not empty analytics results. None of these errors may be converted to zero, an empty result set, a hidden column, a substituted definition, or best-effort SQL.

## Conformance examples

| Scenario | Required outcome |
|---|---|
| Northline requests `occupancy` with a valid reporting period | Read the one signed `official_occupied_units` value for that exact period. |
| Cedar requests `occupancy` | Count live occupied rentable units. |
| A request supplies `tenant_slug: cedar` | `isolated`; no SQL. |
| A Cedar embed guest requests `target_job_cost` | `denied`; no SQL. |
| An unknown guest requests any measure | `unauthorized`; no SQL. |
| In-place rent requires a units-to-leases fanout | `grain`; no SQL. |
| Occupancy history is requested and the registry entry exists | Execute the approved registered query under the Principal context. |
| Occupancy history is requested and the registry entry is absent | `unavailable`; no generated fallback SQL. |
