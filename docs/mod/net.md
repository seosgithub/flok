#Net (net.js)

###Functions

**@telepathy[2]**
`if_net_req(verb, url, params, tp_base)` - Perform an HTTP network request with the given VERB. Assign the network request with the correct telepathy pointer.

###Interrupts
`int_net_cb(tp, success, info)` - An interrupt that a network request has completed (or failed). `success` is a bool vealue. `info` is a JSON value
when successful and a string with an error message (string thats not false) when `success` is false. `tp` is the telepathy pointer passed in via `if_net_req`

------

### Overview 

This driver supports network interfacing. It currently only supports HTTP requests. The `if_net_hint_cancel` can be stubbed if your platform does not support cancelling network requests, but it is best if you can attempt to do so because it will lead to more efficiency.
