# Harbor business taxonomy

## Nouns

| Scope | Business object | Meaning |
|---|---|---|
| Shared | **Principal** | Whoever is asking for data: an embed guest or a Harbor employee using Studio. |
| Shared | **Tenant** | A Harbor customer, such as Northline or Cedar. |
| Shared | **Property** | A managed building or site. Both `is_active` and `active` matter when deciding whether it should be included. |
| Shared | **Unit** | A rentable space. This is also the grain for rent. Common Area does not count as a unit here. |
| Shared | **Lease** | A current or historical agreement for a unit. There can be more than one lease row for a unit. |
| Shared | **Job / work order** | Work on a property, with a stage, status and activity state. |
| Shared | **Invoice / job cost** | The actual cost record. An approved invoice is spend; target job cost is an estimate. |
| Shared record, tenant-specific use | **Official occupancy snapshot / admin pack** | The signed monthly record. Northline reports from it; Cedar keeps it for audit but does not use it as current occupancy. |
| Northline-specific binding | **Official occupancy** | The occupied-unit value in the signed snapshot. The partial unit extract cannot replace it. |
| Cedar-specific binding | **Live occupancy** | The current count of occupied rentable units. Cedar does not use the delayed admin number for this. |
| Harbor definition | **Open jobs** | Harbor's full job filter. Cedar's “not yet invoiced” meaning is a different definition, not an edit to this one. |

Harbor is the vendor. Northline and Cedar are tenants. Studio is Harbor's internal surface, not another tenant or another model.

## Business actions

- The administrator **publishes** the official occupancy snapshot. If Northline's file is late, the meeting moves. We should not calculate a replacement or copy last month's value.
- Northline **reports** the official number. Cedar **reports** the current count of rentable units marked occupied.
- A lease **moves** between current and historical states.
- For occupancy over time, the runtime **retrieves** the existing verified query. It should not make up a date spine.
- A rentable unit **contributes** its market rent whether it is occupied or vacant. The total stays at unit grain.
- A Harbor job **counts as open** only after all stage, status, job activity and property activity checks pass.
- A Cedar job **counts as not yet invoiced** until it has an approved invoice, even if Harbor calls the job closed.
- Once an invoice is **approved**, it contributes to actual spend. The target cost is still only an estimate.
- Embed guests **see** only their tenant's data. Cedar embed guests must not see target job cost.

## Metric classes

| Class | Metric/object | Product meaning |
|---|---|---|
| A | `in_place_rent` | Sum `unit.market_rent` for rentable units. Vacant units stay in; Common Area stays out. |
| A | `rentable_units` | Count rentable units, excluding Common Area. This is the denominator for the live rate. |
| A | `live_occupied_units` | Count rentable units currently marked occupied. This is separate from the official snapshot. |
| A | `vacant_units` | Count rentable vacant units. |
| A | `harbor_open_jobs` | Count jobs only when the complete Harbor filter passes. |
| A | `not_yet_invoiced_jobs` | Count jobs that do not yet have an approved invoice. This is Cedar's separate meaning of “open.” |
| A | `approved_invoice_spend` | Sum approved invoice costs, not target estimates. |
| A | `target_job_cost` | Sum job estimates where access allows it. Cedar embed guests are denied. |
| B | `live_occupancy_rate` | `live_occupied_units / rentable_units`. This works for Cedar. I would not combine Northline's official portfolio number with a denominator from the partial unit extract. |
| C | `occupancy_over_time` | Use the stored verified query for monthly history. The runtime should not generate a replacement query. |
| D | `official_occupied_units` | Read the latest signed value from `occupancy_official`; do not rebuild it from units. |

## Inbound requests

| Request | Decision | Why |
|---|---|---|
| R1 — hardcoded five-day overdue SLA | **Paid exception / time-boxed hack** | Five days is Northline's policy, not a Harbor rule. I would only ship it temporarily; the reusable version needs a configurable SLA. |
| R2 — occupied, vacant, occupancy rate | **Primitive** | The counts and rate are useful for future tenants too. The rate must use an occupancy definition and denominator that refer to the same population. |
| R3 — resolved-result CSV download | **Primitive** | CSV export is reusable across tenants and Studio. It should export the result after the normal resolution and access checks, not resolve the data again. |
| R4 — email VP and draft owner note on a 2% move | **No** | This sends something outside the product, but nobody has defined approval, recipients, duplicate suppression or an audit trail. I would not promise it on tomorrow's call. |
