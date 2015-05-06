#Data types

###controller_info
The controller info contains all things that are necessary to initialize and use a controller. It is never duplicated and stands
as a static structure. Each controller type has one static matching object that is part of the controller table (`ctable`) and can
be looked up as `ctable[controller_name]`.

```javascript
controller_info {
  root_view,     //A constant string of the name of the view this controller sets as it's root view.
  actions        //A dictionary [String:action_info] that corresponds to a dictionary of action_info object's based on the action's name.
}
```

###action_info
The bulk of the controller logic is handled here. Each controller contains an array of pointers to action_info; these action_info objects
dictate what happends when events come in, etc.
```javascript
action_info {
  on_entry      //A function that is called when this action is initialized.
  handlers      //A dictionary [String:f(context, info)] of event handlers for events that occur
}
```
