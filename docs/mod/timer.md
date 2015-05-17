#Timer (timer.js)

###Functions

`if_timer_init(tps)` - Initiate a timer that calls `int_timer` N `tps` (ticsk per second)

###Interrupts
`int_timer` - Called by the device at the rate described in `tps`. This function lives inside the `timer` service's initialization portion.
