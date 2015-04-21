//Socket descriptor, each new socket should increment *before* using it
var if_net_request_socket_index = 0

//A basic get request that supports callbacks
if_net_request = function(verb, url, params) {
  //Get a new socket descriptor
  if_net_request_socket_index += 1
  fd = if_net_request_socket_index

  system.stderr.writeLine("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz")
  $.ajax({url: url, type: verb, data: params}).success(function(data) {
      system.stderr.writeLine("+++++++++++++++++++++++++++++++++++++++++++")
      //int_net_callback(0, 0, 0);
      //data = JSON.parse(data);
    }).error(function(xhr, status, err) {
      system.stderr.writeLine("+++++++++++++++++++++++++++++++++++++++++++")
      console.log("he")
    }).always(function(e) {
      system.stderr.writeLine("------------------------------------")
    })


  return fd
}
