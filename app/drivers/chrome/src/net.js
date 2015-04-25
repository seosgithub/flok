//Socket descriptor, each new socket should increment *before* using it
var if_net_request_socket_index = 0

//A basic get request that supports callbacks
if_net_req = function(verb, url, params, tp_base) {
  console.error(url)
  $.ajax({
    url: url,
    method: verb,
    data: params,
    success: function(data) {
      data = JSON.parse(data);
      int_dispatch([3, "int_net_cb", true, data, tp_base]);
    },
    error: function(xhr, textStatus, err) {
      console.error(err);
    }
  })
}
