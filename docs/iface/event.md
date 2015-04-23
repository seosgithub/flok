#Event (event.js)

### Functions
`if_handle_event(ep, event_name, event)` - Receive an event at some object located at `ep`.  This is a platform defined opaque pointer.

### Interrupts
`int_send_event(ep, event_name, event)` - Send an event back to *Flok* through an event. The `ep` in this case is dependent on the sub-system.
For example, the `vc` (view controller) subsystem will receive any events sent when the `ep` is an opaque pointer to a
surface controller from `ui`.
