__flok_platform = null;

function int_about_poll_cb(info) {
  __flok_platform = info.platform;
  __flok_language = info.language;
  __flok_udid = info.udid;
}

function get_platform() {
  return __flok_platform;
}

function get_udid() {
  return __flok_udid;
}

function get_language() {
  return __flok_language;
}
