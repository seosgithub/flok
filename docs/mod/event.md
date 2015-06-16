#Event (event.js)

### Functions
`if_event(ep, event_name, event)` - Receive an event at some object located at `ep`.  This is a platform defined opaque pointer.

### Interrupts
  * `int_event(ep, ename, event)` - Send an event back to *Flok* through an event. The `ep` in this case is dependent on the sub-system. Dispatching is provided through the `evt` (event vector table). On the flok kernel, using, `reg_evt` and `dereg_evt` will determine what happens post int_event.  If `ep` is no longer valid, the event in ignored. Returns `false` if the destination does not exist and `true` otherwise.
  For example, the `vc` (view controller) subsystem will receive any events sent when the `ep` is an opaque pointer to a
./app/driver/$PLATFORM/config.yml`)
file is used to compile only the modules into the flok kernel that the driver supports.rface controller from `ui`.

  * `int_event_defer(ep, ename, event)` - Same as `int_event` except that the event will be sent to the appropriate receiver at some point in the future, and guaranteed not in the current thread of execution.  This is used internally by the flok kernel; so the fact that it's an external interface dosen't make a lot of sense.

#Deferred (asynchronous) events
When you call `int_event_defer`, as you should be calling it since it's not really meant to be used outside the kernel, you enqueue the event on the `edefer_q` array as a array containing [`ep`, `ename`, `event`]. Shifting this array will yield the oldest `ep`, followed by `ename`, and then the oldest `event` until nothing remains. At this point, nothing happens.  When `int_dispatch` is called, it first checks to see if there is anything on the `edefer_q`. If there is, it takes one thing off the queue and executes it. If there are things remaining on `edefer_q` after completion of `int_dispatch`, the next request going out is marked `incomplete` with a leading `i` (see [dispatch](./dispatch.md)) so that another request will be made to `int_dispatch` in the near future.

### Helper function
`reg_evt(ep, f)` - Register a function to be called when `ep` is sent a message, function looks like function f(ep, ename, info)
`dereg_evt(ep)` - Disable notifications to a function

### Kernel spec related
  * `spec_event_handler(ep, event_name, event)` - This function should send the message `spec_event_handler_res(ep, event_name, event)` if called
  * `int_spec_event_dereg` - This function should de-register 3848392 from being an event 

Additionally, you should register the event pointer `3848392` to call the spec_event_handler_res.
