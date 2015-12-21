__flok_udid = "<no-udid-set>";

function int_udid_init(udid) {
  __flok_udid = udid;
}

function get_udid() {
  return __flok_udid;
}
