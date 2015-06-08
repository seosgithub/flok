<% if @debug %>
spec1_value = "a";

function spec1_init(options) {
  spec1_init_options = options;
}

function spec1_read_sync(ns, bp, key) {
  throw "unsupported"
}

function spec1_read(ns, bp, key) {
  var info = {
    key: key,
    value: spec1_value,
  }

  int_event(bp, "read_res", info);
  vm_cache_write(ns, key, spec1_value);

  //Now change the value
  spec1_value = "b";
}
<% end %>
