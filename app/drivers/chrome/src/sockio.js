//Register a socket.io (Usually in your view controller)
function regSockio(id, socket) {
  id_to_sockio[id] = socket;
}

id_to_sockio = {}

function if_sockio_fwd(id, event_name, bp) {
  <% if @debug %>
    sockio_ensure_test(id);
  <% end %>

  //Grab socket
  var socket = id_to_sockio[id];

  if (socket) {
    //Forward events
    socket.on(event_name, function(info) {
      int_dispatch([3, "int_event", bp, event_name, info]);
    });
  } else {
    <% if @debug %>
      console.error("Couldnt fwd sockio with id: " + id + " (It didn't exist)");
    <% end %>
  }
}

function if_sockio_send(id, event_name, info) {
  <% if @debug %>
    sockio_ensure_test(id);
  <% end %>

  //Grab socket
  var socket = id_to_sockio[id];

  if (socket) {
    socket.emit(event_name, info);
  } else {
    <% if @debug %>
      console.error("Couldnt fwd sockio with id: " + id + " (It didn't exist)");
    <% end %>
  }
}

//Spec helpers
function sockio_ensure_test(id) {
  //Create test socket if necessary
  if (id === "__test__" && !id_to_sockio[id]) {
    id_to_sockio[id] = io("http://localhost:9998");
  }
}
