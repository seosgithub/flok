<% if @debug %>
function pg_spec0_init(ns, options) {
  pg_spec0_watchlist = [];
  pg_spec0_unwatchlist = [];
  pg_spec0_init_params = {ns: ns, options: options};
}

function pg_spec0_watch(id, page) {
  pg_spec0_watchlist.push({id: id, page: page});
}

function pg_spec0_unwatch(id) {
  pg_spec0_unwatchlist.push(id);
}
<% end %>
