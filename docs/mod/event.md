#Event (event.js)

### Functions
`if_event(ep, event_name, event)` - Receive an event at some object located at `ep`.  This is a platform defined opaque pointer.

### Interrupts
`int_event(ep, event_name, event)` - Send an event back to *Flok* through an event. The `ep` in this case is dependent on the sub-system. Dispatching is provided through the `evt` (event vector table). On the flok kernel, using, `reg_ivt` and `dereg_ivt` will determine what happens post int_event.  If `ep` is no longer valid, the event in ignored. Returns `false` if the destination does not exist and `true` otherwise.
For example, the `vc` (view controller) subsystem will receive any events sent when the `ep` is an opaque pointer to a
./app/driver/$PLATFORM/config.yml`)
file is used to compile only the modules into the flok kernel that the driver supports.rface controller from `ui`.

### Kernel spec related
  * `spec_event_handler(ep, event_name, event)` - This function should send the message `spec_event_handler_res(ep, event_name, event)` if called
  * `int_spec_event_dereg` - This function should de-register 3848392 from being an event 

Additionally, you should register the event pointer `3848392` to call the spec_event_handler_res.
