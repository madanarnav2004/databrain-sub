# Harbor semantic layer: design memo

## Occupancy is a binding, not a tenant branch

Northline and Cedar use the same business word for two different sources of truth. The model therefore defines `official_occupied_units` and `live_occupied_units` as separate first-class measures. `official_occupied_units` selects one signed value for a trusted reporting period; `live_occupied_units` counts occupied rentable units in the current extract. The stable business metric `occupancy` permits either implementation, and each Principal receives a semantic profile whose binding selects one of them.

That distinction keeps tenant knowledge out of the runtime. The resolver does not contain `if tenant == northline`; it loads the authenticated Principal's assigned profile, validates that the binding is an allowed implementation of `occupancy`, and compiles that measure. A third tenant can reuse either definition or introduce a reviewed third primitive, then bind it through data. Both embed and Studio resolve through the same model and profile assignment.

## Grain is part of the measure

In-place rent belongs to the unit grain. The seed has two Northline rentable units with market rents of 100 and 200, so the correct result is 300. Each unit also has a current and historical lease. Joining units to leases before summing duplicates both rents and returns 600; `proofs/fanout-wrong.sql` demonstrates that failure directly.

The model makes the safe shape enforceable rather than advisory. `in_place_rent` declares `units` as its entity, excludes Common Area through `rentable_unit`, permits only the many-to-one paths from units to properties and tenants, and forbids leases. The resolver must prove the requested relationships and grouping preserve unit grain before executing SQL. If a plan asks for rent by lease or otherwise introduces the fan-out, the contract returns `grain` and executes nothing. It does not guess at a repair with `DISTINCT`, because that would hide rather than prove the intended calculation.

## The open-jobs predicate is product behavior

Harbor's `harbor_open_jobs` is not a friendly name for `COUNT(jobs.id)`. It is the conjunction of stage, job status, job activity, and both property activity flags. On the seed, all four checks return 2. Omitting `properties.active` admits the Annex job and returns 3.

That difference is a product bug, not a small filter omission: a user acts on the resulting queue and would see work from a property Harbor considers inactive. Keeping the predicate as the named `harbor_open_job` filter makes it reusable and testable wherever the measure appears. Cedar's “not yet invoiced” language is represented separately as `not_yet_invoiced_jobs`, because an approved-invoice test is a different business rule rather than a customization of Harbor's definition.

## What I would throw away

I would not promote Northline's hardcoded five-day overdue rule into the shared layer. Five days is local policy, not a Harbor invariant. If it is needed for an immediate customer commitment, I would label it as a paid, time-boxed exception with an owner and removal date; a reusable product version would require a tenant-configurable SLA and an agreed clock.

I would refuse the request to automatically email a VP and draft an owner note when occupancy moves by two percent. The field notes do not define approval, recipients, duplicate suppression, delivery failure behavior, or an audit trail. Shipping it would turn ambiguous last-mile automation into an external side effect. The semantic layer can expose the trusted result and its provenance without pretending that an undefined communications workflow is a metric.

## What the next tenant and Studio inherit

Tenant three starts with Harbor's nouns, legal relationship graph, rent and job primitives, access defaults, isolation contract, and verified-query boundary. Onboarding becomes a definition exercise: decide which existing occupancy and open-jobs primitives match the tenant, add genuinely new primitives when neither does, and assign a semantic profile. It should not require a fork of the model or another tenant conditional in the resolver.

Studio inherits the same definitions, joins, grain checks, verified queries, and tenant profile bindings as the embedded product. Its Principal is constructed differently: a Harbor session plus an authorized tenant context rather than a guest token. That factory difference can grant explicit internal permissions, such as `view_job_estimates`, without allowing Studio to become a bypass around tenant isolation or semantic meaning.

## Honest limits and ranked next work

This submission specifies the product object and the fail-closed interface; it does not implement a general compiler. The SQL proofs demonstrate intended outputs, but they do not prove that every future plan will preserve grain or enforce access. Profile assignments are shown inline for clarity; a production control plane would need validated, versioned assignment data. The official occupancy measure also depends on a trusted reporting period that the seed does not model as a full execution-context lifecycle. Finally, the verified-query entry is deliberately a registry stub, so availability, versioning, and parameter binding still need an implementation.

I would ask a compiler engineer to build the following next, in order:

1. A typed model loader and pre-execution policy gate that validates Principal construction, request shape, binding resolution, object-level access, and complete isolation before any warehouse call.
2. A grain-aware planner that uses only declared relationships, proves aggregate safety, rejects unsafe reverse traversal, and emits explainable `grain` failures.
3. Row-filter and schema/catalog-rewrite adapters with contract tests showing that the same logical plan cannot cross the Principal's tenant boundary.
4. A versioned verified-query registry that validates parameters, binds trusted Principal context, records provenance, and has no generated-SQL fallback.
5. Golden conformance tests built from these evaluation cases, including assertions that denied and isolated requests make zero warehouse calls.

