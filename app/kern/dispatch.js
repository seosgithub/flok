//Everything to do with dynamic dispatch

//Receive some messages
//Each message is in one flat array
//that has the following format
//[n_args, function_name, *args]
//Here is an example with one call
//  [1, 'print', 'hello world']
//Here is an example with two successive calls
//  [2, 'mul', 3, 4, 1, 'print', 'hello world']
function int_dispatch(q) {
  //Where there is still things left on the queue
  while (q.length > 0) {
    //Grab the first thing off the queue, this is the arg count
    var argc = q.shift();

    <% if @debug %>
      var method_name = q.shift();
      if (this[method_name] === undefined) {
        throw "Couldn't find method named: " + method_name;
      } else {
        this[method_name].apply(null, q.splice(0, argc));
      }
    <% else %>
      //Grab the next thing and look that up in the function table. Pass args left
      this[q.shift()].apply(null, q.splice(0, argc));
    <% end %>
  }

  //Now push all of what we can back
  var dump = [];

  //Send main queue
  if (main_q.length > 0) {
    var out = [0];
    for (var i = 0; i < main_q.length; ++i) {
      out.push.apply(out, main_q[i]);
    }
    dump.push(out);
    main_q = [];
  }

  if (net_q.length > 0 && net_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = net_q.length < net_q_rem ? net_q.length : net_q_rem;

    var out = [1];
    var piece = net_q.splice(0, n);
    for (var i = 0; i < piece.length; ++i) {
      out.push.apply(out, piece[i]);
    }
    dump.push(out);

    net_q_rem -= n;
  }

  if (disk_q.length > 0 && disk_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = disk_q.length < disk_q_rem ? disk_q.length : disk_q_rem;

    var out = [2];
    var piece = disk_q.splice(0, n);
    for (var i = 0; i < piece.length; ++i) {
      out.push.apply(out, piece[i]);
    }
    dump.push(out);

    disk_q_rem -= n;
  }

  if (cpu_q.length > 0 && cpu_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = cpu_q.length < cpu_q_rem ? cpu_q.length : cpu_q_rem;

    var out = [3];
    var piece = cpu_q.splice(0, n);
    for (var i = 0; i < piece.length; ++i) {
      out.push.apply(out, piece[i]);
    }
    dump.push(out);

    cpu_q_rem -= n;
  }

  if (gpu_q.length > 0 && gpu_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = gpu_q.length < gpu_q_rem ? gpu_q.length : gpu_q_rem;

    var out = [4];
    var piece = gpu_q.splice(0, n);
    for (var i = 0; i < piece.length; ++i) {
      out.push.apply(out, piece[i]);
    }
    dump.push(out);

    gpu_q_rem -= n;
  }

  if (dump.length != 0) {
    if_dispatch(dump);
  }
}

function ping() {
  SEND("main", "pong");
}

function ping1(arg1) {
  SEND("main", "pong1", arg1);
}

function ping2(arg1, arg2) {
  SEND("main", "pong2", arg1);
  SEND("main", "pong2", arg1, arg2);
}

function ping3(arg1) {
  if (arg1 == "main") {
    SEND("main", "pong3");
  } else if (arg1 == "net") {
    SEND("net", "pong3");
  } else if (arg1 == "disk") {
    SEND("disk", "pong3");
  } else if (arg1 == "cpu") {
    SEND("cpu", "pong3");
  } else if (arg1 == "gpu") {
    SEND("gpu", "pong3");
  }
}

function ping4(arg1) {
  if (arg1 == "main") {
    SEND("main", "pong4");
  } else if (arg1 == "net") {
    SEND("net", "pong4");
  } else if (arg1 == "disk") {
    SEND("disk", "pong4");
  } else if (arg1 == "cpu") {
    SEND("cpu", "pong4");
  } else if (arg1 == "gpu") {
    SEND("gpu", "pong4");
  }
}

function ping4_int(arg1) {
  if (arg1 == "main") {
  } else if (arg1 == "net") {
    ++net_q_rem;
  } else if (arg1 == "disk") {
    ++disk_q_rem;
  } else if (arg1 == "cpu") {
    ++cpu_q_rem;
  } else if (arg1 == "gpu") {
    ++gpu_q_rem;
  }
}

//Queue something to be sent out
main_q = [];
net_q = [];
disk_q = [];
cpu_q = [];
gpu_q = [];

//Each queue has a max # of things that can be en-queued
//These are decremented when the message is sent (not just queued)
//and then re-incremented at the appropriate int_* mod entry.
net_q_rem = 5;
disk_q_rem = 5;
cpu_q_rem = 5;
gpu_q_rem = 5;
