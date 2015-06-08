#Socket.io (sockio.js)

##Driver Functions
`if_sockio_init(url, sp)` - Initialize a socketio socket with the given `url` and refer to it with `sp`. You must initialize on the main thread to avoid race conditions

`if_sockio_fwd(sp, event_name, ep)` - A request to forward messages from a socket.io socket that represents `id` to the `ep` address as an `if_event` where the event
name is the same as the `socket.io` `event_name` and the information is passed as the `event` field for the `if_event`. Only forward messages matching
`event_name`.

`if_sockio_send(sp, event_name, info)` - Send a socket.io message with the given message `event_name` and `info` to the socket named `id`.

##Additional info
This is functionally different than a debug server that uses the `socket_io` scheme. The debug server is required to handle socket_io by itself.
