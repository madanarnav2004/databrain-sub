# Northline cannot read Cedar

**Model policy:** Principal-based tenant isolation  
**Expected outcome:** `isolated`  
**Warehouse execution:** none

A Northline request is not allowed to add Cedar's slug, tenant ID, schema, or catalog to the plan. Tenant scope comes from the authenticated Principal, so the request cannot choose or override it.

A bad implementation could expose Cedar's rows or return an empty result that incorrectly looks like Cedar has no data. The resolver returns `isolated` and does not run SQL.

