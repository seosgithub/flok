#Controller (controller.js)

### Functions
`if_controller_init(bp, rvp, name, info)` - Initialize a controller that manages the view at `rvp` and contains the address `bp`. All events are sent to `bp` should be handled appropriatlely.

### Spec helpers

### Controller Destruction
Controllers are bound to the lifetime of the view contained at `rvp`.  When `if_free_view` is called, the controller is expected to be removed on the `device` side.

### Events
All controller information is passed through events via `if_event`. When receiving messages, a controller should be able to handle:
  1. `action` - The action has changed (on entered)
    * `from` - A string that represents the 'from' action we came from, it may be null
    * `to`   - A string that represents the 'to' action we are going to, it is never null
    * `info` - A hash with information for the new action
  2. Everything else is a custom event and must be handeled accordingly
