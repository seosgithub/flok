<% if @defines['sockio_pager'] %>
sockio_pager_data = {};
sockio_pager_read_count = 0;

function sockio_pager_read_sync(ns, bp, key) {
  sockio_pager_read_count += 1;

  var info = {
    key: key,
    value: sockio_pager_data[key],
  }
  int_event(bp, "read_res", info);
  vm_cache[ns][key] = sockio_pager_data[key];
}

function sockio_pager_read(ns, bp, key) {
  sockio_pager_read_count += 1;

  var info = {
    key: key,
    value: sockio_pager_data[key],
  }

  int_event(bp, "read_res", info);
  vm_cache[ns][key] = sockio_pager_data[key];
}

function sockio_pager_write(key, value) {
  sockio_pager_data[key] = value;
}
<% end %>
