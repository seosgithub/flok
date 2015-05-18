//Global debug hash
debug_assoc = {}

function if_debug_assoc(base, key, value) {
  if (debug_assoc[base] === undefined) {
    debug_assoc[base] = {};
  }

  debug_assoc[base][key] = value;
}

function if_debug_spec_assoc(base, key) {
  int_dispatch([1, "spec", debug_assoc[base][key]])
} 


function if_debug_spec_send_int_event() {
  int_dispatch([0, "spec"]);
} 

//Debug server
//Automatically launch debug server
$(document).ready(function() {
  debug_socket = io("http://localhost:9999");
  debug_socket.on("attach", function() {
    debug_socket_if_forward = true;
    debug_socket_int_forward = true;

    //Swizzle int_dispatch
    _int_dispatch = int_dispatch;
    int_dispatch = function(q) {
      if (debug_socket && debug_socket_int_forward) {
        debug_socket.emit("int_dispatch", q);
      } else {
        _int_dispatch(q);
      }
    }

    //Forward all int_dispatch events received from the debug server directly to the kernel
    debug_socket.on("int_dispatch", function(msg) {
      debug_socket_int_forward = false;
      int_dispatch(msg);
      debug_socket_int_forward = true;
    });

    //Forward all if_dispatch events directly to the driver
    debug_socket.on("if_dispatch", function(msg) {
      debug_socket_if_forward = false;
      if_dispatch(msg);
      debug_socket_if_forward = true;
    });
  });
});

//Start up the socket.io client
debug_socket = null;

//When forwading events to if_dispatch, if_dispatch will
//normally send those events back to to the server, but
//these originated from the server, so they should always
//be *actually* sent to the if_dispatch interface
debug_socket_if_forward = false;
debug_socket_int_forward = false;
