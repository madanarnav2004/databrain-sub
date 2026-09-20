# Harbor semantic layer

This submission turns Harbor's field notes into one semantic model shared by the embedded tenant experience and Harbor Studio. It defines the business vocabulary, legal relationships, metric implementations, Principal-based access rules, tenant isolation behavior, and the resolver's fail-closed contract.

The submission intentionally does not include a general query compiler. The SQL proofs show what the layer should emit for approved plans; the Markdown proofs document requests that must be refused or dispatched to a registered query.

## Walkthrough

[Watch the 5–8 minute Loom walkthrough](https://www.loom.com/share/4c269a49a4e44de6b83228f554f4ef1f).

## Repository guide

- `taxonomy.md` — Harbor's business objects, actions, metric classes, and product decisions
- `model.yaml` — entities, legal relationships, measures, tenant bindings, access rules, isolation, and verified queries
- `contract.md` — request and Principal interface plus the resolver's pre-execution checks and errors
- `proofs/` — gold-number SQL, fail-closed cases, and the intentional fan-out demonstration
- `memo.md` — design reasoning, inheritance, limitations, and next steps
- `ai-tool-usage.md` — AI usage disclosure
- `warehouse/` — the supplied SQLite schema and seed data, included unchanged for reproducibility

## Requirements

- SQLite 3
- A POSIX-compatible shell

## Build the warehouse

From the repository root:

```sh
sqlite3 harbor.db < warehouse/schema.sql
sqlite3 harbor.db < warehouse/seed.sql
```

The schema script drops and recreates the supplied tables, so running both commands produces a fresh local database.

## Run the numeric proofs

```sh
sqlite3 harbor.db < proofs/northline-in-place-rent.sql
sqlite3 harbor.db < proofs/cedar-in-place-rent.sql
sqlite3 harbor.db < proofs/northline-occupancy.sql
sqlite3 harbor.db < proofs/cedar-occupancy.sql
sqlite3 harbor.db < proofs/northline-open-jobs.sql
sqlite3 harbor.db < proofs/fanout-wrong.sql
```

Expected results:

| Proof | Result | Meaning |
|---|---:|---|
| Northline in-place rent | `300` | Rentable units at unit grain; Common Area excluded |
| Cedar in-place rent | `200` | Rentable units at unit grain; vacant unit included |
| Northline occupancy | `29` | Official signed snapshot |
| Cedar occupancy | `2` | Live occupied rentable units |
| Northline open jobs | `2` | Complete Harbor job and property filter bundle |
| Intentional fan-out query | `600` | Demonstration of the unit-to-lease bug; not a valid rent result |

`fanout-wrong.sql` is deliberately unsafe. It shows why a real rent-by-lease plan must return the contract's `grain` error instead of executing.

## Fail-closed proofs

Some correct outcomes do not have executable warehouse SQL:

- Cedar target job cost returns `denied`.
- A Northline request that tries to select Cedar returns `isolated`.
- An unknown embed identity returns `unauthorized`.
- In-place rent joined or grouped by lease returns `grain`.
- Occupancy history retrieves `harbor.occupancy_over_time`; it does not generate replacement SQL.

Each case belongs in its own Markdown proof under `proofs/`. A rejected request executes no warehouse SQL. If the registered occupancy-history query is unavailable, the resolver returns `unavailable` rather than inventing a date spine.

## Key design decisions

- `occupancy` is a stable business name with profile-based bindings: Northline resolves to `official_occupied_units`, while Cedar resolves to `live_occupied_units`.
- `in_place_rent` is protected at unit grain and cannot traverse into leases.
- `harbor_open_jobs` owns the complete stage, status, job-active, and two-property-flag predicate.
- Tenant scope comes from the authenticated Principal, never from a request-supplied tenant ID, slug, schema, or catalog.
- Access is deny-by-default, and explicit denial takes precedence over an allow.
