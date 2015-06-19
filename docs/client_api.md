#Client API
Client API covers controller action event handlers.

### Controller MACROS
  * Embed(view_controller_name, spot_name, context) - Embed a view controller with the name `view_controller_name` inside the current view controller at the spot with a context
  * Goto(action_name) - Change actions
  * Request(service_insatnce_name, ename, params) Initiate a service.  See [Services](./services.md) for more info.  
  * Send(event_name, info) - Send a custom event on the main queue.
  * Raise(event_name, info) - Will send an event to the parent view controller (and it will bubble up, following `event_gw` which is set in `Embed` as the parent controller
  * Lower(spot_name, event_name, info) - Send an event to a particular spot
  * Helpers
    * Page Modification - See [User Page Modification Helpers](./vm.md#user_page_modification_helpers) for a list of functions available.

### Controller Event Handlers
  * Variables
    * `context` - The information for the controllers context
    * `params` - What was passed in the event
    * `__base__` - The address of the controller
    * `__info__` - Holds the `context`, current action, etc. See [Datatypes](./datatypes.md)
### Controller on_entry (actions)
    * `context` - The information for the controllers context
    * `__base__` - The address of the controller
    * `__info__` - Holds the `context`, current action, etc. See [Datatypes](./datatypes.md)
### Controller on_entry (global)
    * `context` - The information for the controllers context
    * `__base__` - The address of the controller
