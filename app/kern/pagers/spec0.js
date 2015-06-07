<% if @debug %>
spec0_data = {};
spec0_read_count = 0;

function spec0_init(options) {
  spec0_init_options = options;
}

function spec0_read_sync(ns, bp, key) {
  spec0_read_count += 1;

  var info = {
    key: key,
    value: spec0_data[key],
  }
  int_event(bp, "read_res", info);
  vm_cache[ns][key] = spec0_data[key];
}

function spec0_read(ns, bp, key) {
  spec0_read_count += 1;

  var info = {
    key: key,
    value: spec0_data[key],
  }

  int_event(bp, "read_res", info);
  vm_cache[ns][key] = spec0_data[key];
}

function spec0_write(key, value) {
  spec0_data[key] = value;
}
<% end %>
