# Proof checklist

Write one proof per eval case. Plans must not contain tenant ids or slugs; tenant scope comes from the Principal. This folder intentionally contains no generated proof SQL yet.

- [ ] **`northline-in-place-rent` — `300`** (not `600` or `350`). Look at `units.market_rent` and `units.is_common_area`; scope units through `properties.tenant_id` to `tenants`. Keep the measure at unit grain and do not join `leases`.
- [ ] **`cedar-in-place-rent` — `200`** (not `400`). Use the same unit-grain fields and tenant relationship as Northline; vacant rentable units remain included.
- [ ] **`northline-occupancy` — `29`** (not `2`). Look at `occupancy_official.occupied_units`, `as_of`, and its relationship to `tenants`. Use the latest official snapshot, not the unit extract.
- [ ] **`cedar-occupancy` — `2`** (not `3`). Look at `units.status` and `units.is_common_area`, scoped through `properties` to `tenants`. Do not use `occupancy_official`.
- [ ] **`northline-open-jobs` — `2`** (not `3` or `6`). Check `jobs.stage`, `job_status`, `is_active`, and `property_id`, plus both `properties.is_active` and `properties.active`.
- [ ] **`cedar-target-cost-denied` — `denied`** (not `180` or `0`). Check the Cedar embed access rule for `jobs.target_job_cost` and the `target_job_cost` measure. This case should execute no warehouse SQL.
- [ ] **`northline-cannot-read-cedar` — `isolated`**. Check that the plan cannot supply `tenants.slug`, `tenant_id`, schema, or catalog and that tenant scope comes from the Northline Principal. This case should execute no warehouse SQL.
- [ ] **`unknown-principal` — `unauthorized`**. Check Principal creation and authentication; no warehouse table or field should be queried.
- [ ] **`fanout-rent-by-lease-is-not-rent` — `grain` or a value other than `600`**. Inspect the one-to-many `units` → `leases` relationship through `leases.unit_id` and protect `units.market_rent` at unit grain. Prefer the contract's `grain` refusal.
- [ ] **`occupancy-over-time-is-verified` — registered query**. Point to `verified_queries.occupancy_over_time` in `model.yaml`. The required history is not proven from the seed tables; do not generate a date spine or replacement SQL.

Also add the required `fanout-wrong.sql` later, clearly labeled as the bug and expected to return `600` for Northline. It is intentionally not created here.
