//Event handler table
evt = {};

//Event defer queue
edefer_q = [];

function int_event(ep, event_name, info) {
  <% if @debug %>
    if (ep.constructor !== String && ep.constructor !== Number) { throw "int_event was given either something that wasn't a string or number for ep: '" + (ep.constructor) + "' and the value was: '" + ep + "'"};
  <% end %>

  var f = evt[ep];
  if (f != undefined) {
    f(ep, event_name, info);
    return true;
  } else {
    return false;
  }
}

function reg_evt(ep, f) {
  evt[ep] = f;
}

function dereg_evt(ep) {
  delete evt[ep];
}

function int_event_defer(ep, ename, info) {
  <% if @debug %>
    if (ep.constructor !== String && ep.constructor !== Number) { throw "int_event_defer was given either something that wasn't a string or number for ep: '" + (ep.constructor) + "' and the value was: '" + ep + "'"};
  <% end %>
  edefer_q.push(ep);
  edefer_q.push(ename);
  edefer_q.push(info);
}

//Spec helpers
////////////////////////////////////////////////////////////////
function spec_event_handler(ep, event_name, info) {
  SEND("main", "if_event", ep, event_name, info);
}
reg_evt(3848392, spec_event_handler);

function int_spec_event_dereg() {
  dereg_evt(3848392);
}
////////////////////////////////////////////////////////////////
