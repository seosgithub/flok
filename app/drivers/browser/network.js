drivers = window.drivers || {}
drivers.network = {}

$(document).ready(function() {
  //drivers.network.request("GET", "http://test.services.fittr.com/ping", {}, null);
})

//All requests are bound to this table and removed when cancelled
drivers.network.callbackTable = {}
drivers.network.socketIndex = 0  //The current index of the socket, incremented for new sockets

//A basic get request that supports callbacks
drivers.network.request = function(verb, url, params, completion) {
  //Store callback in the table
  var socketIndex = drivers.network.socketIndex++
  drivers.network.callbackTable[socketIndex] = true

  $.ajax({
    url: url,
    type: verb,
    data: params,
    success: function(data) {
      data = JSON.parse(data);
      completion = completion || function() {}
      if (completion != null) {
        //Callback if possible
        if (drivers.network.callbackTable[socketIndex] === true) { 
          delete drivers.network.callbackTable[socketIndex];
          completion(data, false); 
        }
      }
    },
    error: function(xhr, status, err) {
      if (drivers.network.callbackTable[socketIndex] === true) { 
          delete drivers.network.callbackTable[socketIndex];
          completion({"message":status}, true); 
        }
    }
  })

  return socketIndex
}

drivers.network.cancel_request = function(socket) {
  res = drivers.network.callbackTable[socket];
  console.log("Cancelling: " + res);
  //Clear callback
  delete drivers.network.callbackTable[socket]
}
