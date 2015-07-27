//Configure pg_dummy0
<% [0].each do |i| %>
  function pg_dummy<%= i %>_init(ns, options) {
    pg_dummy<%= i %>_init_params = {ns: ns, options: options};
    pg_dummy<%= i %>_ns = ns;

    pg_dummy<%= i %>_spec_did_init = true;

    pg_dummy<%= i %>_write_vm_cache_clone = [];
  }

  function pg_dummy<%= i %>_watch(id, page) {
  }

  function pg_dummy<%= i %>_unwatch(id) {
  }

  function pg_dummy<%= i %>_write(page) {
    //Deep clone vm_cache at call time
    //Used by specs looking to see if HD lookup happends
    pg_dummy<%= i %>_write_vm_cache_clone.push(JSON.parse(JSON.stringify(vm_cache)));
  }
<% end %>
