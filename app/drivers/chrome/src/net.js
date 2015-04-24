//Socket descriptor, each new socket should increment *before* using it
var if_net_request_socket_index = 0

//A basic get request that supports callbacks
if_net_req = function(verb, url, params) {
  $.ajax({
    nethu
    url: url,
    data: params,
    method: verb,
    success: function(data, status, xhr) {

    },
    error: function(xhr, status, err) {
    }
  })
}
