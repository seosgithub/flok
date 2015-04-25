//Socket descriptor, each new socket should increment *before* using it
var if_net_request_socket_index = 0

//A basic get request that supports callbacks
if_net_req = function(verb, url, params) {
  console.error(url)
  $.ajax({
    url: url,
    method: verb,
    data: params,
    success: function(data) {
      console.error("success")
    },
    error: function(xhr, textStatus, err) {
      console.error(err);
    }
  })
}
