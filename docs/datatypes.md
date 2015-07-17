#Data types
Instances labeled `static` mean that they are not dynamically created and are meant to be used by many things. Somewhat like a singleton or a const in a functional language.

###ctable_entry (static)
The controller info contains all things that are necessary to initialize and use a controller. It is never duplicated and stands
as a static structure. Each controller type has one static matching object that is part of the controller table (`ctable`) and can
be looked up as `ctable[controller_name]`.

```javascript
ctable_entry {
  root_view,     //A constant string of the name of the view this controller sets as it's root view.
  actions,       //A dictionary [String:action_info] that corresponds to a dictionary of action_info object's based on the action's name.
  spots,         //An array fo spot names for this controller, by default, the 'main' spot is counted as 1 spot.
  name,          //The name of the controller, useful for certain lookup operations, this is also the ctable key
  __init__,      //A function that is called when this controller is created. Signals service connection and the controller on_entry bits.
  Additionally, all interval timers are configured here based on their unique names. Actions that are not active will not receive these events (they
  will be ignored).
  __dealloc__    //A function that is called when this controller is destroyed via parent controller switching actions in Goto. Signals services d/c
}
```

###action_info (static)
The bulk of the controller logic is handled here. Each controller contains an array of pointers to action_info; these action_info objects
dictate what happends when events come in, etc.
```javascript
action_info {
  on_entry      //A function that is called when this action is initialized.
  handlers      //A dictionary [String:f(base)] of event handlers for events that occur. Timer events are given a unique name and stored here like
  `3toht_5_sec`
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
  context: {}, //A hash that contains context information (user supplied)
  action: //The name of the current action that is active
  cte:    //The ctable entry pertaining to this controller
  embeds: //An array of arrays, where position 0 is the spot after `main`, each element in the array is a view controller base pointer.
  stack: [{action:, embeds:}] //When pushing, the stack contains a copy of the controller_info's action's and a reference to the embeds from the previous layer. 
  event_gw: //When an event cannot be serviced, it is given to the gateway to continue propogating
}
```
