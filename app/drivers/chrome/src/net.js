//Socket descriptor, each new socket should increment *before* using it
var if_net_request_socket_index = 0

//A basic get request that supports callbacks
if_net_req = function(verb, url, params, tp_base) {
  $.ajax({
    url: url,
    method: verb,
    data: params,
    dataType: "json",
    success: function(data) {
      int_dispatch([3, "int_net_cb", tp_base, true, data]);
    },
  error: function(xhr, textStatus, err) {
    int_dispatch([3, "int_net_cb", tp_base, false, textStatus]);
  }
})
}
