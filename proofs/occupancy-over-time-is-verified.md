# Occupancy history uses the verified query

**Model object:** `occupancy_over_time`  
**Expected outcome:** retrieve `harbor.occupancy_over_time`  
**Generated replacement SQL:** none

Occupancy over time is a verified-query request, not a query for the resolver to invent. For a valid request such as the last 12 months, the resolver retrieves `harbor.occupancy_over_time`, applies tenant scope from the Principal, and uses that Principal's occupancy binding.

It must not create a new date spine or generate replacement `generate_series` SQL. If the registered query is missing, the resolver returns `unavailable` instead of guessing.

