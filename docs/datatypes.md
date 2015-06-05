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
  spots,         //An array fo spot names for this controller
  name,          //The name of the controller, useful for certain lookup operations, this is also the ctable key
  __init__       //A function that is called when this controller is created
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
  context: {}, //A hash that contains context information (user supplied)
  action: //The name of the current action that is active
  cte:    //The ctable entry pertaining to this controller
  embeds: //An array of arrays, where position 0 is the spot after `main`, each element in the array is a view controller base pointer.
}
```

###stable_entry (static)
Each service instance has it's own ctable entry. Unlike controller, service *instances* actually meta-class instances. You still need to 
'instantize' the service instance via a `service_info`. Additionally, services are not meant to have multiple copies of. You may have
multiple instances declared, but each will have it's own name. This is a completetly static structure

```javascript
stable_entry {
  name,           //The name of the service instance
  type,           //'daemon' or 'agent'
  on_wakeup,
  on_sleep,
  on_disconnect,
  handler         //A dictionary [String:f(context, info)] of event handlers for events that occurs
}
```

###service_info
Each service instance is a singleton; however, the singleton is created and destroyed if it is an `agent` and no longer needed.
service_info {
  context: {}, //Information held by the service
  ste,         //Service table entry
}
