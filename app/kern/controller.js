//The view-controller hierarchy is managed by this set of functions.

//Embed a view-controller into a named spot. If spot is null, then it is assumed
//you are referring to the root-spot.
function _embed(vc_name, sp, context) {
  //Lookup VC ctable entry
  var cte = ctable[vc_name];

  //Find the root view name
  var vname = cte.root_view;

  //Get spot names
  var spots = cte.spots;

  //Actions
  var actions = cte.actions;

  //Construct the view
  var base = tels(spots.length);
  SEND("main", "if_init_view", vname, context, base, spots);
  SEND("main", "if_attach_view", base, sp);

  //TODO: choose action
  var action = Object.keys(cte.actions)[0];

  //Create controller information struct
  var info = {
    context: {},
    action: action,
    cte: cte,
    embeds: [],
  };

  //Register controller base with the struct, we already requested base
  tel_reg_ptr(info, base);

  //Call the on_entry function with the base address
  cte.actions[action].on_entry(base);

  //Register the event handler callback
  reg_evt(base, controller_event_callback);

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
  }
}
