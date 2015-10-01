function int_dlink_notify(url, params) {
  <% if @debug %>
    int_dlink_spec_last_request = [url, params];
  <% end %>

  //Currently sends off to the sister dlink-service by default
  dlink_notify_handler(url, params);
}

//Spec tracks the last given notify request
<% if @debug %>
int_dlink_spec_last_request = null;
function get_int_dlink_spec() {
  SEND("main", "get_int_dlink_spec", int_dlink_spec_last_request);
}
<% end %>
