//Global debug hash
debug_kv = {}

function if_debug_assoc(base, key, value) {
  if (debug_kv[base] === undefined) {
    debug_kv[base] = {};
  }

  debug_kv[base][key] = value;
}

function if_debug_spec_assoc(base, key) {
  int_dispatch([1, "spec", debug_kv[base][key]])
} 
