//Receive some messages
//Each message is in one flat array
//that has the following format
//[n_args, function_name, *args]
//Here is an example with one call
//  [1, 'print', 'hello world']
//Here is an example with two successive calls
//  [2, 'mul', 3, 4, 1, 'print', 'hello world']
function if_dispatch(qq) {
  if (qq[0] == 'i') {
    qq.shift();
    if_dispatch_call_int_end = true
  } else {
    if_dispatch_call_int_end = false
  }

  //If debug socket is attached, forward events to it
  //and do not process the events
  <% if @mods.include? "debug" %>
    if (debug_socket && debug_socket_if_forward) {
      debug_socket.emit("if_dispatch", qq);
    } else {
  <% end %>

  //Get a priority queue
  while (qq.length > 0) {
    var q = qq.shift();

    //The very first thing is the queue type
    var queueType = q.shift();

    //Where there is still things left on the queue
    while (q.length > 0) {
      //Grab the first thing off the queue, this is the arg count
      var argc = q.shift();

      //Grab the next thing and look that up in the function table. Pass args left
      this[q.shift()].apply(null, q.splice(0, argc));
    }
  }

  //Continuation of the debug_socket at linke 10
  <% if @mods.include? "debug" %>
    }
  <% end %>


  if (if_dispatch_call_int_end) {
    if_dispatch_call_int_end = false;
    int_dispatch([])
  }
}

function ping() {
  int_dispatch([0, "pong"])
}

function ping1(arg1) {
  int_dispatch([1, "pong1", arg1])
}

function ping2(arg1, arg2) {
  int_dispatch([1, "pong2", arg1])
  int_dispatch([2, "pong2", arg1, arg2])
}

function ping_nothing() {
}
