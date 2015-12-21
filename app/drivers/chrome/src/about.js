
function if_about_poll() {
  var udid = localStorage.getItem("__flok_udid"); 
  if (udid === null) {
    udid = __flok_chrome_guid()
    localStorage.setItem("__flok_udid", udid);
  }

  int_dispatch([1, "int_about_poll_cb", {
    "platform": navigator.userAgent,
    "language": navigator.language,
    "udid": udid,
  }]);
}
