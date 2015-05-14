#Debug (debug.js)
The debug module provides information to the client (driver) module such as events that are available for a particular view.

### Functions
`if_debug_set_kv(key, value)` - Synchronously set a key / value pair on the client.

### Kernel spec related
  * `if_debug_spec_kv(key)` - When this message is received, the client shall return a message called `spec` containing the value
