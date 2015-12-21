#Net (net.js)

###Functions

**@telepathy[2]**
`"if_net_req(verb, url, params, tp_base)` - Perform an HTTP network request with the given VERB. Assign the network request with the correct telepathy pointer.
`"if_net_req2(verb, headers, url, params, tp_base)`" - Perform an HTTP network request, but accept some HTTP headers in the form of a dictionary.  Useful for authentication or requesting content types.

###Interrupts
`int_net_cb(tp, code, info)` - An interrupt that a network request has completed (or failed). 

  * `tp` - The original tele-pointer given for the request passed in for `if_net_req`
  * `code` - an integer vealue that indicates whether the request could be completed or not.  If it's greater than 0, it's an HTTP code response from the server. if it's -1, then it's a failed response.
  * `info` - If the response was succesful, i.e. `code > 0` then the info here should be an arbitrary JSON dictionary containing the server's response. If the network request failed, then this contains a internal error message.

`get_int_net_cb_spec()` - Sends [[0, 1, "get_int_net_cb_spec", int_net_cb_spec]]


###Behavior, when int_net_cb is called, it should make a function request to `tp` and pass `tp`, code` and `info` to this function. Additionally, the
kernel should set `function(tp, a, b) { int_net_cb_spec = [tp, a, b]; }` at address integer `-3209284741`.

------

### Overview 

This driver supports network interfacing. It currently only supports HTTP requests. The `if_net_hint_cancel` can be stubbed if your platform does not support cancelling network requests, but it is best if you can attempt to do so because it will lead to more efficiency.
