//Configure pg_mem0, pg_mem1, pg_mem2
<% [0, 1, 2].each do |i| %>
  function pg_mem<%= i %>_init(ns, options) {
    pg_mem<%= i %>_init_params = {ns: ns, options: options};
    pg_mem<%= i %>_ns = ns;

    <% if @debug %>
      pg_mem<%= i %>_spec_did_init = true;
    <% end %>
  }

  function pg_mem<%= i %>_watch(id, page) {
  }

  function pg_mem<%= i %>_unwatch(id) {
  }

  function pg_mem<%= i %>_write(page) {
    vm_transaction_begin();
    vm_cache_write(pg_mem<%= i %>_ns, page);
    vm_transaction_end();
  }
<% end %>
