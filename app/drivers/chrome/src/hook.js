//Driver side interface
///////////////////////////////////////////////////////////////////////////////////////////////////////////
function if_hook_event(name, info) {
  <% if @debug %>
    if_hook_spec_dump_rcvd_events_log.push({name: name, info: info});
  <% end %>

  //Call the appropriate registered handler
  if (hookEventHandlers[name] !== undefined) {
    hookEventHandlers[name](info);
  }
}

<% if @debug %>
  //Track all events sent to if_hook_event
  var if_hook_spec_dump_rcvd_events_log = []
  function if_hook_spec_dump_rcvd_events() {
    int_dispatch([1, "if_hook_spec_dump_rcvd_events_res", if_hook_spec_dump_rcvd_events_log]);
  }
<% end %>
///////////////////////////////////////////////////////////////////////////////////////////////////////////

//User helpers
///////////////////////////////////////////////////////////////////////////////////////////////////////////
var hookEventHandlers = {};
function onHookEvent(eventName, handler) {
  hookEventHandlers[eventName] = handler;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////
