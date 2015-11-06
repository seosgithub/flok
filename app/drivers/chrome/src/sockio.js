sp_to_sockio = {}

function if_sockio_init(url, sp) {
  sp_to_sockio[sp] = io(url, {
    "forceNew": true
  });
}

function if_sockio_fwd(sp, event_name, bp) {
  //Grab socket
  var socket = sp_to_sockio[sp];

  if (socket) {
    //Forward events
    socket.on(event_name, function(info) {
      int_dispatch([3, "int_event", bp, event_name, info]);
    });
  } else {
    <% if @debug %>
      console.error("Couldnt fwd sockio with sp: " + sp + " (It does not exist)");
    <% end %>
  }
}

function if_sockio_send(sp, event_name, info) {
  //Grab socket
  var socket = sp_to_sockio[sp];

  if (socket) {
    socket.emit(event_name, info);
  } else {
    <% if @debug %>
      console.error("Couldnt fwd sockio with sp: " + sp + " (It does not exist)");
    <% end %>
  }
}
