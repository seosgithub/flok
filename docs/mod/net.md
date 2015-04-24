#Net (net.js)

###Functions

`if_net_req(verb, url, params)` - Perform an HTTP network request with the given VERB. Returns a `opaque object` that represents this network request. We will call this pointer `fd`

`if_net_hint_cancel(fd)` - Cancel a currently running network request. If this is not supported, or fails, it is ok, because flok will not trigger any associated callbacks anyway.

###Interrupts
`int_net_cb(success, info)` - An interrupt that a network request has completed (or failed). `success` is a bool vealue. `info` is a JSON value when successful and a string with an error message when `success` is false.

------

### Overview 

This driver supports network interfacing. It currently only supports HTTP requests. The `if_net_hint_cancel` can be stubbed if your platform does not support cancelling network requests, but it is best if you can attempt to do so because it will lead to more efficiency.
