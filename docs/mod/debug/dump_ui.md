#Debug Dump UI
The `int_debug_dump_ui` dumps the view-controller, view, and spot hierarchy. This is used in viewers like the *Seagull* client. This is a very expensive
message as it sends back a `if_event` with the name `debug_dump_ui_res` and the address `-333` with a very large payload of many embedded hashes.

##Hash linked list
The payload returned in `int_debug_dump_ui` is a *linked* list of sorts; There is a basic type of node that looks like:

```js
Node {
  children: [Node],
  type: "$node_class"
}
```

Ontop of the base node, the type defines a child class of the node:

  * `vc` - View Controller
    * `name` - The name of the view controller (human friendly)
    * `action` - Current action name (human friendly)
    * `ptr` - The base pointer of this view controller
    * `event_handlers` - A list of events that the current action is capabable of handling
  * `view` - View
    * `name` - The name of the view
    * `ptr` - The pointer to the view
  * `spot` - Spot inside a view controller's root view
    * `name` - The name of the spot
    * `ptr` - The pointer of this spot location

Note that all view controllers have one `main` spot, this is actually just the `view` (Every view has a view controller, and vice versa).  So technically,
the spots beyond the `main` spot are actually children of the view managed by the view controller.
Another way to say that is that all `vc`'s will have one child and it will be a view.'

Example payload:

```ruby
{
  type: "spot",
  name: "root",
  ptr: 0,
  children: [
    {
      name: "dashboard"
      type: "vc",
      action: "index",
      view: "dashboard",
      ptr: 2,
      children: [
        {
          type: "view",
          name: "container (main)",
          ptr: 3
          children: [
            {
              type: "spot",
              name: "content",
              ptr: 4,
              children: []
            }
          ]
        }
      ]
    }
  ]
}
```
