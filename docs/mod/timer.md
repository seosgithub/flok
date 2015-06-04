#Timer (timer.js)

###Functions
`if_timer_init(tps)` - Initiate a timer that calls `int_timer` N `tps` (ticsk per second). This is always called via the cpu scheduling class (3)

###Interrupts
`int_timer` - Called by the device at the rate described in `tps`. This function lives inside the `timer` service's initialization portion.

###Callout
The kernel's `int_timer` function gets sent to `callout_wakeup()` located in `callout.js`.
