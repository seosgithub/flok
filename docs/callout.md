#Callout - Kernel timer manager
The function `callout_wakeup()` embodies the time management functions of the kernel; this includes maintaining periodic
and interval timers and to send a custom event to the given port.

##Registration
You may register for a timer event via `reg_timer(ep, ename, ticks)`. If ticks is negative, the timer will be periodic (re-fire).
You may not de-register for an event; if `ep` no longer points to an object, then the timer will not do anything; and if it's periodic,
the timer will be de-registered at that point.
