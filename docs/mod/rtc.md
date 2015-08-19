#Real Time Clock (rtc.js)

###Driver
`if_rtc_init()` - Initialize the RTC module.

###Interrupts
`int_rtc(epoch)` - Called every second to indicate that a second has passed.

###Helper functions
`time()` - Retrieves the time as an integer based on the unix epoch (Seconds since 1970)
