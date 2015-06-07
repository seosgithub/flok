<% if @defines['sockio_pager'] %>
  sockio_pager_data = {};
  //SEND(1, 2, "if_sockio_init", localhost")

  function sockio_pager_read_sync(ns, bp, key) {
    throw "sockio_pager does not support read_sync"
  }

  function sockio_pager_read(ns, bp, key) {
    var info = {
      key: key,
      value: sockio_pager_data[key],
    }

    int_event(bp, "read_res", info);
    vm_cache[ns][key] = sockio_pager_data[key];
  }

  function sockio_pager_write(key, value) {
    throw "sockio_pager does not support write"
  }
<% end %>
