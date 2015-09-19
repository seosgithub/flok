#Hook
The hook module allows the client to receive hook_event messages. This is a required module.

###Driver messages
`if_hook_event(name, info)` - The name of the hook event and the information received.

####Driver spec functions (only required in debug mode)
`if_hook_spec_dump_rcvd_events` - Schedules the event `if_hook_spec_dump_res` to be sent out with a message in the form of `[1, "if_hook_spec_dump_rcvd_events_res", [{name:name, info:info}, ...]}` where the array contains
the parameters to all the calls to `if_hook_event` with the example hash and in sequential order where the oldest is the greatest index.
