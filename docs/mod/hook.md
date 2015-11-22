#Hook
The hook module allows the client to receive hook_event messages. This is a required module.

###Driver messages
`if_hook_event(name, info)` - The name of the hook event and the information received.

###Spec requirements
When built for spec testing, the client should have two hook handlers for the hook events named `test` and `test2`.
These hooks should both respond with a interrupt named `hook_dump_res` with the info `{name: "XXXX", info: info}`
where the name is either `test` or `test2` and the info is the received payload.
