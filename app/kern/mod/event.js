//Event handler table
evt = {};

//Event defer queue
edefer_q = [];

function int_event(ep, event_name, info) {
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
