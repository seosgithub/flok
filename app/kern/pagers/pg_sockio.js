//Configure pg_sockio
<% [0].each do |i| %>
  function pg_sockio<%= i %>_init(ns, options) {
    pg_sockio<%= i %>_ns = ns;

    <% if @debug %>
      pg_sockio<%= i %>_spec_did_init = true;
    <% end %>
  }

  function pg_sockio<%= i %>_watch(id, page) {
  }

  function pg_sockio<%= i %>_unwatch(id) {
  }

  function pg_sockio<%= i %>_write(page) {
  }
<% end %>
