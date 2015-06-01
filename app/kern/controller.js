//The view-controller hierarchy is managed by this set of functions.

<% if @debug %>
  //Maintain type information for pointers
  //Is it a spot ('spot'), view (main spot) ('view'), or view controller ('vc')?
  debug_ui_ptr_type = {};

  //Keep track of what view are embedded into spots
  debug_ui_spot_to_views = {};
  debug_ui_view_to_spot = {};

  //The first view controller that contains a view attached to the root spot (0)
  debug_root_vc = null;
<% end %>

//Embed a view-controller into a named spot. If spot is null, then it is assumed
//you are referring to the root-spot.
function _embed(vc_name, sp, context, event_gw) {
  //Lookup VC ctable entry
  var cte = ctable[vc_name];

  //Find the root view name
  <% if @debug %>
    if (cte === undefined) {
      throw "Tried to embed a flok controller named: '" + vc_name + "' but you have not created that controller yet, add controller :" + vc_name + "do ...";
    }
  <% end %>
  var vname = cte.root_view;

  //Get spot names
  var spots = cte.spots;

  //Actions
  var actions = cte.actions;

  //Allocate a list of tels, the base is the actual 'vc', followed by
  //the 'main' spot, and so on
  var base = tels(spots.length+1);

  //TODO: choose action
  var action = Object.keys(cte.actions)[0];

  spots.unshift("vc") //Borrow spots array to place 'vc' in the front => ['vc', 'main', ...]
    //Initialize the view at base+1 (base+0 is vc), and the vc at base+0
    SEND("main", "if_init_view", vname, {}, base+1, spots);
    
    SEND("main", "if_controller_init", base, base+1, vc_name, context);

    <% if @debug and @mods.include? "debug" %>
      //Keep track of the view-controller attached to root spot (0)
      if (sp == 0) {
        debug_root_vc = base;
      }

      //Track vc
      debug_ui_ptr_type[base] = 'vc';
      debug_ui_ptr_type[base+1] = 'view';
      //Start at 2 because spot[0] is (currently) acting as vc, spot[1] is main view
      for (var i = 2; i < spots.length; ++i) {
        debug_ui_ptr_type[base+i] = 'spot';
      }

      //Track what view is going into the spot
      debug_ui_spot_to_views[sp] = debug_ui_spot_to_views[sp] || [];
      debug_ui_spot_to_views[sp].push(base+1);
      debug_ui_view_to_spot[base+1] = sp;
    <% end %>

    SEND("main", "if_attach_view", base+1, sp);
  spots.shift() //Un-Borrow spots array (it's held in a constant struct, so it *cannot* change)

  //Prep embeds array, embeds[0] refers to the spot bp+2 (bp is vc, bp+1 is main)
  var embeds = [];
  for (var i = 1; i < spots.length; ++i) {
    embeds.push([]);
  }

  //Create controller information struct
  var info = {
    context: context,
    action: action,
    cte: cte,
    embeds: embeds,
    event_gw: event_gw
  };

  //Register controller base with the struct, we already requested base
  tel_reg_ptr(info, base);

  //Register the event handler callback
  reg_evt(base, controller_event_callback);

  //Call the on_entry function with the base address
  cte.actions[action].on_entry(base);

  //Notify action
  var payload = {from: null, to: action};
  SEND("main", "if_event", base, "action", payload);

  return base;
}

//Called when an event is received
function controller_event_callback(ep, event_name, info) {
  //Grab the controller instance
  var inst = tel_deref(ep);

  //Now, get the ctable entry
  var cte = inst.cte;

  //Now find the event handler
  var handler = cte.actions[inst.action].handlers[event_name];
  if (handler !== undefined) {
    handler(ep, info);
  } else {
    //Recurse
    if (inst.event_gw != null) {
      controller_event_callback(inst.event_gw, event_name, info);
    }
  }
}
