#Callout - Kernel timer manager
The function `callout_wakeup()` embodies the time management functions of the kernel; this includes maintaining periodic
and interval timers and to send a custom event to the given port.

##Registration
You may register for a timer event via `reg_timeout(ep, ename, ticks)`. This will wait `ticks` before firing.
To continually fire, you may use `reg_interval(ep, ename, ticks)` which will continue to fire every `ticks`. If `ep` is no longer in the `evt`, then
the entry will no longer exist.  (the timer will automatically be de-registered)
