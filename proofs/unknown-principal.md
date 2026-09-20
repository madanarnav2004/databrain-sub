# Unknown Principal is unauthorized

**Principal:** `acme-not-a-tenant`  
**Expected outcome:** `unauthorized`  
**Warehouse execution:** none

The embed Principal factory cannot authenticate this identity or connect it to a tenant scope and semantic profile. The request therefore stops before the resolver tries to calculate in-place rent or inspect any warehouse table.

A bad implementation might fall back to a default tenant or run an unscoped query. The resolver returns `unauthorized` instead.

