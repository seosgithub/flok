function if_per_set(ns, key, value) {
  localStorage.setItem(ns+"___"+key, value);
}

function if_per_del(ns, key) {
  localStorage.removeItem(ns+"___"+key);
}

function if_per_del_ns(ns) {
}

function if_per_get(s, ns, key) {
}

function if_per_get_sync(s, ns, key) {
  var res = localStorage.getItem(ns+"___"+key);
  int_dispatch([2, "int_per_get_res", s, res]);
}
