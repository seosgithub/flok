//The view-controller hierarchy is managed by this set of functions.

//Embed a view-controller into a named spot. If spot is null, then it is assumed
//you are referring to the root-spot.
function embed(vc_name, sp, context) {
  //Lookup VC ctable entry
  var cte = ctable[vc_name];

  //Find the root view name
  var vname = cte.root_view;

  //Get spot names
  var spots = cte.spots;

  //Construct the view
  var base = tels(1);
  SEND("main", "if_init_view", vname, context, base, spots);
  SEND("main", "if_attach_view", base, sp);
}
