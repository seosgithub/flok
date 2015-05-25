//Event handler table
evt = {};

function int_event(ep, event_name, info) {
  <% if @debug %>
    if (typeof ep == 'string' || ep instanceof String) {
      console.log("WARN: received ep of '" + ep + "' that was a string!!!");
      console.log("name: " + name);
      console.log("info: " + JSON.stringify(info));
    }
  <% end %>

  var f = evt[ep];
  if (f != undefined) {
    f(ep, event_name, info);
  }
}

function reg_evt(ep, f) {
  evt[ep] = f;
}

function dereg_evt(ep) {
  delete evt[ep];
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
