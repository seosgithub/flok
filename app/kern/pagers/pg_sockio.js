//Configure pg_sockio
<% [0].each do |i| %>
  function pg_sockio<%= i %>_init(ns, options) {
    pg_sockio<%= i %>_ns = ns;

    if (options.url === undefined) {
      throw "pg_sockio<%= i %> was not given a url in options";
    }

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
