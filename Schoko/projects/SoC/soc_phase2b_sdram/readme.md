# Description
*Phase 2 sdram* This manually exercises the sdram directly

1) Allow SDRAM to initialize
2) Setup signals:
   - setup address
   - data
   - ??

# Button stepping

We do stepping via a lock-step approach. When the button goes low we set a lock that prevents the next step from moving forward until the button is released.