#Debug Server
The debug server should be started whenever a driver is built in `debug` mode. The server supported should be defined in `debug_attach`.
the behavior of one of the protocols listed below. You should declare which server type you use in the driver because the spec testers use this
information. The key `debug_attach` holds a protocol key like `socket_io`. This key should only be in the `DEBUG` section of your `config.yml`
The `debug` module implements the `debug server`. Although, the server is a seperate
piece of code that dosen't fit into the same `if` and `int` paradigm. The specs in the `debug server` also use various `debug` module helpers.

## `socket_io` Protocol
This protocol states that the driver must repeadeately attempt to connect to the socket.io port located at `localhost:9999`.

### Attach event
After `attach` is received from socket.io, the driver should forward all `if_dispatch` events to `if_dispatch`
of the `socket.io` and forward all `int_dispatch` events going to the flok server to `int_dispatch` of socket.io.  The driver should then
forward all `int_disptach` events it receives to `int_dispatch` of the flok server and all `if_dispatch` events socket.io it receives to `if_dispatch` 
event on the driver. The information passed along for these messages should be the same as the originals.

Attach may be called multiple times. If it is, the driver is to ignore this.
