//Configure pg_spec0 and pg_spec1
<% if @debug %>
  <% [0, 1].each do |i| %>
    function pg_spec<%= i %>_init(ns, options) {
      pg_spec<%= i %>_watchlist = [];
      pg_spec<%= i %>_unwatchlist = [];
      pg_spec<%= i %>_init_params = {ns: ns, options: options};
      pg_spec<%= i %>_ns = ns;
    }

    function pg_spec<%= i %>_watch(id, page) {
      pg_spec<%= i %>_watchlist.push({id: id, page: page});
    }

    function pg_spec<%= i %>_unwatch(id) {
      pg_spec<%= i %>_unwatchlist.push(id);
    }

    function pg_spec<%= i %>_write(page) {
      vm_transaction_begin();
      vm_cache_write(pg_spec<%= i %>_ns, page);
      vm_transaction_end();
    }
  <% end %>
<% end %>
