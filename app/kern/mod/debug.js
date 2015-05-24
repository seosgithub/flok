////////////////////////////////////////////////////////////
//Eval
////////////////////////////////////////////////////////////
function int_debug_eval(str) {
  var res = eval(str);
  var payload = {
    res: res
  }

  SEND("main", "if_event", -333, "eval_res", payload);
}

function debug_eval_spec() {
  return 'hello';
}

////////////////////////////////////////////////////////////
//Dump hierarchy
////////////////////////////////////////////////////////////
function int_debug_dump_ui() {
  //The root spot is not a real spot, it's just the 
  //starting node that is conventionally refered to
  //as view with 'pointer 0'.
  var payload = {
    name: "root",
    type: "spot",
    ptr: 0,
    children: []
  };

  //Recurse starting with the root view controller
  //that was attached to the 'root spot' at ptr 0. There
  //is only one view controller that will exist here, so
  //it's set to the only child
  if (debug_root_vc) {
    var rvc = {};
    dump_ui_recurse(debug_root_vc, rvc);
    payload.children.push(rvc);
  }

  //Notify with the 'debug' pointer of -333
  SEND("main", "if_event", -333, "debug_dump_ui_res", payload);
}

function dump_ui_recurse(ptr, node) {
  //What kind of thing does ptr point to? Look it up in the
  //special debug_ui_ptr_type hash we made
  //vc - View Controller (always inside a spot)
  //view - View (always matched below view controller)
  //spot - Spot (always inside a view)
  if (debug_ui_ptr_type[ptr] === 'vc') {
    node['type'] = 'vc';
    node['ptr'] = ptr;

    //Live controller instance
    var cinfo = tel_deref(ptr);
    var cte = cinfo.cte;

    //Get action
    var action = cinfo.action;
    node['action'] = action;

    //Get name from the ctable reference
    node['name'] = cte.name;

    //Get a list of events that this action responds to
    node['events'] = Object.keys(cte.actions[action].handlers);

    //Recurse with the 'main' view (ptr+1) in this view controller's
    //first child slot. (there is only one view per view controller)
    //and it's called 'main' and is always the first child of the vc.
    node['children'] = [{}];
    dump_ui_recurse(ptr+1, node['children'][0])
  } else if (debug_ui_ptr_type[ptr] === 'view') {
    node['type'] = 'view';
    node['ptr'] = ptr;

    //The name will be part of the view controller,
    //we can get the vc ptr by subtracting one from
    //this view because each view controller's 'main'
    //spot is this view, and there's only one.
    var vc_ptr = ptr-1;
    var cinfo = tel_deref(vc_ptr); //Live controller instance
    var cte = cinfo.cte;  //Controller table entry (static)
    node['name'] = cte.root_view;

    //Get a listing of spots, ignore spot 0
    //because it's actually this view (the main spot)
    node['children'] = [];
    for (var i = 1; i < cte.spots.length; ++i) {
      var sn = {};
      sn['name'] = cte.spots[i];  //Set the name here, easiest way
      sn['ptr'] = ptr+i;
      dump_ui_recurse(ptr+i, sn);
      node['children'].push(sn);
    }
  } else if (debug_ui_ptr_type[ptr] === 'spot') {
    //Name and ptr is already set in the view recurse portion above
    node['type'] = 'spot';

    node['children'] = [];

    //Do we have children, are these spots actually filled?
    var attached_view_ptrs = debug_ui_spot_to_views[ptr];
    if (attached_view_ptrs !== undefined) {
      for (var i = 0; i < attached_view_ptrs.length; ++i) {
        //View controller is located at 1 below the view pointer
        var bp = attached_view_ptrs[i]-1;

        //Create a new controller node
        var cnode = {};
        dump_ui_recurse(bp, cnode);
        node['children'].push(cnode);
      }
    }
  }
}

////////////////////////////////////////////////////////////
//Controller context
////////////////////////////////////////////////////////////
function int_debug_controller_context(bp) {
  var payload = tel_deref(bp).context;
  SEND("main", "if_event", -333, "debug_controller_context_res", payload);
}
