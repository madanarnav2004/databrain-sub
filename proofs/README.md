# Proof status

The numeric results below were reproduced against a fresh database built from `warehouse/schema.sql` and `warehouse/seed.sql`.

## Verified SQL proofs

- [x] `northline-in-place-rent.sql` returns `300`, not `600` or `350`.
- [x] `cedar-in-place-rent.sql` returns `200`, not `400`.
- [x] `northline-occupancy.sql` returns `29`, not `2`.
- [x] `cedar-occupancy.sql` returns `2`, not `3`.
- [x] `northline-open-jobs.sql` returns `2`, not `3` or `6`.
- [x] `fanout-wrong.sql` intentionally returns `600`, demonstrating the unit-to-lease fan-out bug.

## Required non-SQL case proofs

These cases must be documented as explicit resolver outcomes. Rejected requests execute no warehouse SQL.

- [x] `cedar-target-cost-denied.md` — `denied`, not `180`, `0`, or `null`.
- [x] `northline-cannot-read-cedar.md` — `isolated`; tenant scope comes from the Principal.
- [x] `unknown-principal.md` — `unauthorized`; Principal construction fails before planning.
- [x] `fanout-rent-by-lease-is-not-rent.md` — `grain`; the real request is refused rather than returning `600`.
- [x] `occupancy-over-time-is-verified.md` — retrieve `harbor.occupancy_over_time`; do not generate replacement SQL.

## Run the SQL proofs

From the repository root:

```sh
sqlite3 harbor.db < warehouse/schema.sql
sqlite3 harbor.db < warehouse/seed.sql

sqlite3 harbor.db < proofs/northline-in-place-rent.sql
sqlite3 harbor.db < proofs/cedar-in-place-rent.sql
sqlite3 harbor.db < proofs/northline-occupancy.sql
sqlite3 harbor.db < proofs/cedar-occupancy.sql
sqlite3 harbor.db < proofs/northline-open-jobs.sql
sqlite3 harbor.db < proofs/fanout-wrong.sql
```

Expected output, in order: `300`, `200`, `29`, `2`, `2`, `600`.
