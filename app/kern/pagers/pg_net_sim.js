<% if @debug %>
function pg_net_sim_init(ns, options) {
  pg_net_sim_spec_did_init = true;
  pg_net_sim_ns = ns;

  //Set timer to tick every 2 seconds
  reg_evt(-9393, pg_net_sim_tick_handler);
  reg_interval(-9393, "tick", 4*2);

  pg_net_sim_waiting_for_response = [];
}

function pg_net_sim_tick_handler(ep, ename, info) {
  while (pg_net_sim_waiting_for_response.length > 0) {
    var e = pg_net_sim_waiting_for_response.shift();
    vm_transaction_begin();
      vm_cache_write(pg_net_sim_ns, pg_net_sim_stored_pages[e.id]);
    vm_transaction_end();
  }
}

function pg_net_sim_watch(id, page) {
  if (pg_net_sim_stored_pages[id] === undefined) {
    throw "Could not get page with id: " + id;
  }

  pg_net_sim_waiting_for_response.push({id: id});
}

function pg_net_sim_unwatch(id) {
}

function pg_net_sim_write(page) {
  vm_cache_write(pg_net_sim_ns, page);
}

//Special support function to simulate pages stored
//on a server
pg_net_sim_stored_pages = {};
function pg_net_sim_load_pages(pages) {
  for (var i = 0; i < pages.length; ++i) {
    var page = pages[i];
    pg_net_sim_stored_pages[page._id] = page;
  }
}
<% end %>
