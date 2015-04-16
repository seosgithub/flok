//$(document).ready(function() {
  //flok_request("GET", "http://test.services.fittr.com/ping", {}, null);
//})

//All requests are bound to this table and removed when cancelled
flok.net = {};
flok.net.callbackTable = {};
flok.net.socketIndex = 0  //The current index of the socket, incremented for new sockets

//A basic get request that supports callbacks
flok.net.request = function(verb, url, params, completion) {
  //Store callback in the table
  var socketIndex = flok.net.socketIndex++
  flok.net.callbackTable[socketIndex] = true

  $.ajax({
    url: url,
    type: verb,
    data: params,
    success: function(data) {
      data = JSON.parse(data);
      completion = completion || function() {}
      if (completion != null) {
        //Callback if possible
        if (flok.net.callbackTable[socketIndex] === true) { 
          delete flok.net.callbackTable[socketIndex];
          completion(data, false); 
        }
      }
    },
    error: function(xhr, status, err) {
      if (flok.net.callbackTable[socketIndex] === true) { 
          delete flok.net.callbackTable[socketIndex];
          completion({"message":status}, true); 
        }
    }
  })

  return socketIndex
}

flok.net.cancel_request = function(socket) {
  res = flok.net.callbackTable[socket];
  //Clear callback
  delete flok.net.callbackTable[socket]
}
