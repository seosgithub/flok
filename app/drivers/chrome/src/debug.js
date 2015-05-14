//Global debug hash
debug_kv = {}

function if_debug_set_kv(key, value) {
  debug_kv[key] = value;
}

function if_debug_spec_kv(key) {
  int_dispatch([1, "spec", debug_kv[key]])
} 
