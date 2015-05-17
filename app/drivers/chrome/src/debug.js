//Global debug hash
debug_assoc = {}

function if_debug_assoc(base, key, value) {
  if (debug_assoc[base] === undefined) {
    debug_assoc[base] = {};
  }

  debug_assoc[base][key] = value;
}

function if_debug_spec_assoc(base, key) {
  int_dispatch([1, "spec", debug_assoc[base][key]])
} 

function if_debug_attach() {
}
