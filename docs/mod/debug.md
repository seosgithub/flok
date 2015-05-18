#Debug (debug.js)
The debug module provides information to the client (driver) module such as events that are available for a particular view.

### Driver Messages
`if_debug_assoc(base, key, value)` - Associate a key and value for an object called base (usually a pointer or string)

#### Kernel
`int_debug_eval(str)` - Send an eval request; the str must not contain any newlines. Will respond by sending back a `if_event` message to
the port -333 with the message name `eval_res` and the info as `{info: res}` where `res` is what ever was retrieved by the eval.

### Driver Spec related
  * `if_debug_spec_assoc(base, key)` - When this message is received, the client shall return a message called `spec` containing the value
  * `if_debug_spec_send_int_event` - This function should send the message `[0, "spec"]` to `int_event`.

### Kernel spec related
  * The function `debug_eval_spec` is in the kernel and should return 'hello'. This is called by the specs that test eval to make sure
    that eval is working. It is never used in a message

### config.yml variables
  * `debug_attach` - See [Debug Server](../debug_server.md) for details

### Debug Server
The debug module should also provide a debug server. Details of the server are layed out in [Debug Server](../debug_server.md)
