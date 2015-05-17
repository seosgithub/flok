#Debug (debug.js)
The debug module provides information to the client (driver) module such as events that are available for a particular view.

### Functions
`if_debug_assoc(base, key, value)` - Associate a key and value for an object called base (usually a pointer or string)
`if_debug_serv_start` - Start a debug server that can accept requests for attachment. The server must comply with the protocols established in
[debug server](../debug_server.md)

### Kernel spec related
  * `if_debug_spec_assoc(base, key)` - When this message is received, the client shall return a message called `spec` containing the value

#### Configuration variables
  * `debug_attach` - See [Debug Server](../debug_server.md)
