//Configure pg_dummy0
<% [0].each do |i| %>
  function pg_dummy<%= i %>_init(ns, options) {
    pg_dummy<%= i %>_init_params = {ns: ns, options: options};
    pg_dummy<%= i %>_ns = ns;

    pg_dummy<%= i %>_spec_did_init = true;
  }

  function pg_dummy<%= i %>_watch(id, page) {
  }

  function pg_dummy<%= i %>_unwatch(id) {
  }

  function pg_dummy<%= i %>_write(page) {
  }
<% end %>
