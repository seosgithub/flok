#Data types
Instances labeled `static` mean that they are not dynamically created and are meant to be used by many things. Somewhat like a singleton or a const in a functional language.

###controller_info (static)
The controller info contains all things that are necessary to initialize and use a controller. It is never duplicated and stands
as a static structure. Each controller type has one static matching object that is part of the controller table (`ctable`) and can
be looked up as `ctable[controller_name]`.

```javascript
controller_info {
  root_view,     //A constant string of the name of the view this controller sets as it's root view.
  actions,       //A dictionary [String:action_info] that corresponds to a dictionary of action_info object's based on the action's name.
  spots,         //An array fo spot names for this controller
}
```

###action_info (static)
The bulk of the controller logic is handled here. Each controller contains an array of pointers to action_info; these action_info objects
dictate what happends when events come in, etc.
```javascript
action_info {
  on_entry      //A function that is called when this action is initialized.
  handlers      //A dictionary [String:f(context, info)] of event handlers for events that occur
}
```

###controller_info
Created when a new controller is established via `_embed`. The tele-pointer system maintains the pointers to controller instances
via `tel_reg`.  The `main` view pointer acts as the base-pointer for the controller. This means that on *our* side, the `main` view
pointer refers to the controller and on the `driver` side, the base pointer refers to our root-view. This would be apparent if we received
an event from the root-view as it would the same pointer to the controller. If we sent an event to the `driver`, then that `driver` would
receive the event in the `root` view of the controller.

```javascript
controller_info {
  base: 333,   //The base pointer of the root-view, and the tele-pointer of this controller.
  context: {}, //A hash that contains context information (user supplied)
}
```
