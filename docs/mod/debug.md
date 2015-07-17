#Debug (debug.js)
The debug module provides information to the client (driver) module such as events that are available for a particular view.

**This is depreciated and may no longer works correctly especially with view hierarchies that contain push / pop semantics. (Multiple layers in push
/pop hierarchies will not reveal push / pop semantics, it will look flat)**

### Driver Messages
`if_debug_assoc(base, key, value)` - Associate a key and value for an object called base (usually a pointer or string)

`if_debug_highlight_view(vp, on)` - Highlight the view **or spot** that is given in `vp`. Used in some debuggers (like seagull) to let users select
the hierarchy and see it's equivalent in the client. `on` is a bool that indicates whether something should be highlihted or not. (toggle).
If given a view pointer that's 0 or dosen't exist, it should just ignore it.

#### Kernel
`int_debug_eval(str)` - Send an eval request; the str must not contain any newlines. Will respond by sending back a `if_event` message to
the port -333 with the message name `eval_res` and the info as `{info: res}` where `res` is what ever was retrieved by the eval.

`int_debug_dump_ui` - See [Debug Dump UI](./debug/dump_ui.md) for specifics.

`int_debug_controller_describe(bp)` - Retreive information about a controller. Sends a `if_event` to port `-333` named `debug_controller_describe_res` with the payload of the controller's
describe at `bp`.
  * describe returns
    * `context` - The context of the controller which is `cinfo.context`
    * `events` - The list of events the current controller action will respond to, **current action not the same as displayed if it's changed**

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
