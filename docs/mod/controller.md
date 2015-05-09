#Controller (controller.js)

### Functions
`if_controller_init(bp, name, info)` - Initialize a controller that manages the view at `bp`. All events sent to `bp`
should be intercepted by this controller and this controller shall send events to the same `bp` when transmitting
things like buttons.

### Spec helpers
