//Import express
var express = require('express');
var ws = require("nodejs-websocket")
var io = require('socket.io')();

var app = express();

clients = []

app.get('/search', function (req, res) {
  res.json(clients)
});

//Start GUI Rest services
var server = app.listen(3334, function () {
  var host = server.address().address;
  var port = server.address().port;
});

var socketToId = {};

io.on('connection', function(socket) {
  var id = "hello";
  clients.push({
    name: "Chrome (localhost)",
    platform: "chrome",
    id: id,
  });

  socketToId[socket] = id;

  socket.on("disconnect", function() {
    var idx = -1;
    for (var i = 0; i < clients.length; ++i) {
      if (clients[i].id === socketToId[socket]) {
        idx = i;
        break;
      }
    }
    clients.splice(idx, 1);
  });
});
io.listen(9999);

function go() {
  console.log("SERVICES_STARTED");
}
setTimeout(go, 1000)
