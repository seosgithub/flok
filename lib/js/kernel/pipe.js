//Pipes handle all communication and provide 1-way channels

//All the pipe 'routes'.  Each pipe is a number that represents the receiver.
//This table looks up the receiving function
pipe_routes = {};

//Create a new pipe to a receiver
//will call 'callback' when new data is sent over this pipe
//and returns a opaque pipe pointer (pp)
function pipe(callback) {
  var pp = UUID();
  pipe_routes[pp] = callback;
  return pp;
}

//Send a message over a pipe
function send(pp, msg) {
  var callback = pipe_routes[pp];
  if (callback === undefined) {
    throw "Could not pipe_send because no route existed for pipe with pointer: "+pp+" with msg: "+msg;
  }

  callback(msg);
}

//Delete a pipe
function close(pp) {
  delete flock_pipe_routes[pp];
}

//List all pipes
function lspipe() {
  for (pp in pipe_routes) {
    console.log(pp + " - " + pipe_routes[pp]);
  }
}
