# Harbor semantic-layer business taxonomy

## Nouns

| Scope | Business object | Meaning |
|---|---|---|
| Shared | **Principal** | The actor and surface requesting data: a tenant's embed guest or a Harbor employee in Studio. It supplies isolation and permissions; it is not a product fork. |
| Shared | **Tenant** | A Harbor customer such as Northline or Cedar. Tenant identity comes from the Principal, never the query plan. |
| Shared | **Property** | A managed building/site. Both `is_active` and `active` are meaningful eligibility flags. |
| Shared | **Unit** | A rentable space and the grain of rent. Common Area is not a unit for rent or occupancy. |
| Shared | **Lease** | A unit agreement with current and historical records. It can establish live occupancy but must not multiply unit-grain rent. |
| Shared | **Job / work order** | Property work moving through stage, status, activity, and invoicing. |
| Shared | **Invoice / job cost** | An actual cost record. An approved invoice is spend; target job cost is only an estimate. |
| Shared record, local authority | **Official occupancy snapshot / admin pack** | A signed monthly record. It is Northline's reporting authority, but Cedar retains it only for audit. |
| Tenant binding — Northline | **Official occupancy** | Occupied units from the signed snapshot; the partial unit extract is not a substitute. |
| Tenant binding — Cedar | **Live occupancy** | Current occupied rentable units; the lagging official snapshot is not a substitute. |
| Harbor product | **Open-jobs definition** | Harbor's named filter bundle. Cedar's “not yet invoiced” jobs are a second definition, not an override. |

Harbor is the vendor; Northline and Cedar are tenants; Studio is Harbor's internal surface. They are Principal contexts, not separate products or models.

## Business actions

- An administrator **publishes/signs** an official occupancy snapshot. If Northline's file is late, the owner meeting moves; the product does not recompute or carry forward a value.
- The resolver **binds** an occupancy request to either the official or live object authorized for that Principal.
- A lease **becomes current or historical**; only a current lease can establish live occupied status. Historical occupancy is retrieved through a verified query.
- A unit is **included in the rent book** when rentable, whether occupied or vacant. Rent is aggregated before any lease-grain join.
- A Harbor job **counts as open** only when its stage is not Cancelled/Closed, status is not Rejected, the job is active, and both property activity flags are true.
- A Cedar job **counts as not yet invoiced** until it has an approved invoice, regardless of Harbor stage.
- An invoice is **approved** and then contributes to approved invoice spend; an estimate never substitutes for spend.
- The runtime **authorizes and isolates** every request from its Principal, and may **export resolved results** to CSV.

## Metric classes

| Class | Metric/object | Product meaning |
|---|---|---|
| A | `in_place_rent` | Sum rentable `unit.market_rent` at unit grain; vacant units included and Common Area excluded. |
| A | `live_occupied_units` | Count rentable occupied units using the current/live state. Separate from official occupancy. |
| A | `vacant_units` | Count rentable vacant units. |
| A | `harbor_open_jobs` | Count jobs satisfying the complete Harbor stage/status/job/property filter bundle. |
| A | `not_yet_invoiced_jobs` | Count jobs without an approved invoice; Cedar's separate business meaning. |
| A | `approved_invoice_spend` | Sum approved Invoice job costs, not target estimates. |
| A | `target_job_cost` | Sum of estimates where authorized; denied to the Cedar embed Principal. |
| B | `occupancy_rate` | Occupied divided by the matching rentable denominator. Cedar can use live inventory; official occupancy needs an official denominator and must not mix Northline's portfolio count with the partial extract. |
| C | `occupancy_over_time` | Stored verified query for monthly history. Retrieve it; do not invent a date spine, window, or multi-CTE query. |
| D | `official_occupancy_snapshot` | Select the signed warehouse/file value. Never re-derive it from the unit extract. |

## Inbound requests

| Request | Decision | Why |
|---|---|---|
| R1 — hardcoded five-day overdue SLA | **Paid exception / time-boxed hack** | Five days is Northline policy, not a Harbor invariant; a future product primitive would require a configurable SLA rather than a baked-in constant. |
| R2 — occupied, vacant, occupancy rate | **Primitive** | These reusable A/A/B measures belong in the layer, while each Principal's occupied numerator remains explicitly bound. |
| R3 — resolved-result CSV download | **Primitive** | Exporting an already authorized result is a reusable product capability across embed and Studio, not tenant logic. |
| R4 — email VP and draft owner note on a 2% move | **No** | Alert orchestration, recipients, and generated communications sit outside this semantic layer; the layer may supply an authorized metric result only. |
