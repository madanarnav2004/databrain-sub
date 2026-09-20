# Cedar target cost is denied

**Model object:** `target_job_cost`  
**Expected outcome:** `denied`  
**Warehouse execution:** none

The Cedar embed guest is a valid Principal, but the model explicitly blocks this guest from seeing target job cost. A bad implementation might return Cedar's total of `180`, hide it as `0`, or replace it with `null`; all three would make a denied field look like valid data.

The resolver returns `denied` and stops before running SQL.

