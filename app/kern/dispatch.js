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

    //Grab the next thing and look that up in the function table. Pass args left
    this[q.shift()].apply(null, q.splice(0, argc));
  }

  //Now push all of what we can back
  var dump = [];

  //Send main queue
  if (main_q.length > 0) {
    main_q.unshift(0);
    dump.push(main_q);
    main_q = [];
  }

  if (net_q.length > 0 && net_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = net_q.length < net_q_rem ? net_q.length : net_q_rem;

    net_q.unshift(1);
    dump.push(net_q.splice(0, n+1));
    net_q_rem -= n;
  }

  if (disk_q.length > 0 && disk_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = disk_q.length < disk_q_rem ? disk_q.length : disk_q_rem;

    disk_q.unshift(2);
    dump.push(disk_q.splice(0, n+1));
    disk_q_rem -= n;
  }

  if (cpu_q.length > 0 && cpu_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = cpu_q.length < cpu_q_rem ? cpu_q.length : cpu_q_rem;

    cpu_q.unshift(3);
    dump.push(cpu_q.splice(0, n+1));
    cpu_q_rem -= n;
  }

  if (gpu_q.length > 0 && gpu_q_rem > 0) {
    //Always pick the minimum between the amount remaining and the q length
    var n = gpu_q.length < gpu_q_rem ? gpu_q.length : gpu_q_rem;

    gpu_q.unshift(4);
    dump.push(gpu_q.splice(0, n+1));
    gpu_q_rem -= n;
  }

  if_dispatch(dump);
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
