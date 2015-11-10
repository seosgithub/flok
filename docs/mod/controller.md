#Controller (controller.js)

### Depends
  * ui.js - The controller module depends on the `ui` module as it passes a pointer to a view in `if_controller_init`

### Functions
`if_controller_init(bp, rvp, name, context)` - Initialize a controller that manages the view at `rvp` and contains the address `bp`. All events are sent to `bp` should be handled appropriatlely.
The `rvp` pointer will always be an initialized (but not attached) view. When receiving an action, the view is guaranteed to be attached at that time. Context is what the controller was initialized with.
**All controllers should be the same name as their views, there is a 1-1 relationship between views and controllers that was not originally true in the first version. Now views and contollers act as one**

### Spec helpers

### Controller Destruction
Controllers are bound to the lifetime of the view contained at `rvp`.  When `if_free_view` is called, the controller is expected to be removed on the `device` side.

### Events
All controller information is passed through events via `if_event`. When a controller receives an event, some events have
special meanings based on the `name` field of the event:
  1. `action` - The action has changed (on entered). This is also called after if_controller_init with `null`. Action is **always** called with an
  attached view. 
    * `from` - A string that represents the 'from' action we came from, it may be null
    * `to`   - A string that represents the 'to' action we are going to, it is never null
    * `info` - A hash with information for the new action
  2. Everything else is a `custom event` and must be handeled accordingly

### Spec messages (driver side)
`if_spec_controller_init` - Setup anything necessary for the spec tests, this may include adding prototype controller js (for chrome), etc
`if_spec_controller_list` - Sends a message back called `spec` that contains an array of controller base pointers that were initialized via `if_controller_init`
but have not been destroyed.

### Spec fixtures (driver side)
There should be two identical controllers called `spec_one_spot` and `spec_blank` that can be initialized and should respond in the following ways when it receives an action and
event:
  Note: an event is **not** a raw message, it is through the message of `int_event`, i.e. `[3, $NAME, bp, "custom_event", info]`. The event name may either be `foo` or `bar`
  Sends a **event** back called `action_rcv` containing `{from: from, to: to, info: info}` when an action is received
  Sends a **event** back called `custom_rcv` containing a hash that looks like `{name: name, info: event}` when a custom event is received

  Additionally, add a controller named `spec_blank_sends_context` that sends back the initialization context when it is created via the event named `context` with the initialization (context) parameters.
