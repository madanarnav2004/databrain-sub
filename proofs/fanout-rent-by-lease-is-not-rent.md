# Rent by lease is refused

**Model object:** `in_place_rent`  
**Expected outcome:** `grain`  
**Warehouse execution:** none

In-place rent is defined at unit grain, while joining or grouping it by lease can repeat the same unit. The intentionally incorrect `fanout-wrong.sql` shows the problem: Northline's correct rent of `300` becomes `600` because each rentable unit has two lease rows.

The resolver does not try to hide the problem with `DISTINCT` or another guessed repair. It returns `grain` before running the unsafe query.

