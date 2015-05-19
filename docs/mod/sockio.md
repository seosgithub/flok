#Socket.io (sockio.js)

##Driver Functions
`if_sockio_fwd(id, event_name, base)` - A request to forward messages from a socket.io socket that represents `id` to the `base` address as an `if_event` where the event
name is the same as the `socket.io` `event_name` and the information is passed as the `event` field for the `if_event`. Only forward messages matching
`event_name`.

`if_sockio_send(id, event_name, info)` - Send a socket.io message with the given message `event_name` and `info` to the socket named `id`.

##Driver spec
The driver should support binding a socket named `__test__` and it should connect to `http://localhost:9998`.

##Additional info
This is functionally different than a debug server that uses the `socket_io` scheme. The debug server is required to handle socket_io by itself.
