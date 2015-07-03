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
    //Check if page exists
    if (vm_cache[pg_mem<%= i %>_ns][page._id]) {

      (function() {
        var _page = vm_cache[pg_mem<%= i %>_ns][page._id];
          var __page__ = {
            _head: _page._head,
            _next: _page._next,
            _id: _page._id,
            _type: _page._type,
          }

          __page__.entries = [];
          for (var i = 0; i < _page.entries.length; ++i) {
            __page__.entries.push(JSON.parse(JSON.stringify(_page.entries[i])));
        }

          __page__.entries[0]._sig = "aaaa";
          __page__.entries[0].value  = "fuck" + (Math.random() * 100).toString();
          vm_rehash_page(__page__);

        function go() {
          vm_cache_write_sync(pg_mem<%= i %>_ns, __page__, "");
        }
        setTimeout(go, 1000);

      vm_rehash_page(page);
      vm_cache_write_unsynced(pg_mem<%= i %>_ns, page);

      })();
    } else {
      vm_cache_write(pg_mem<%= i %>_ns, page);
    }
  }
<% end %>
