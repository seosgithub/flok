function pg_mem0_init(ns, options) {
  pg_mem0_watchlist = [];
  pg_mem0_unwatchlist = [];
  pg_mem0_init_params = {ns: ns, options: options};
  pg_mem0_ns = ns;

  <% if @debug %>
    pg_mem0_spec_did_init = true;
  <% end %>
}

function pg_mem0_watch(id, page) {
}

function pg_mem0_unwatch(id) {
}

function pg_mem0_write(page) {
  vm_cache_write(pg_mem0_ns, page);
}
