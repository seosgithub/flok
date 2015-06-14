<% if @debug %>
spec2_value = "a";

function spec2_init(options) {
  spec2_init_options = options;
}

function spec2_read_sync(ns, bp, key) {
  throw "unsupported"
}

function spec2_read(ns, bp, key) {
  var info = {
    key: key,
    value: spec2_value,
  }

  int_event(bp, "read_res", info);
  vm_cache_write(ns, key, spec2_value);

  //Now change the value
  spec2_value = "b";
}

function spec2_watch(ns, key) {
}

function spec2_spec_trigger() {
  vm_notify("user", "my_key");
}
<% end %>
