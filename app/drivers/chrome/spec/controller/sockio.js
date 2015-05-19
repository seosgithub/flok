//Testing to make sure we can register to socket.io

$(document).ready(function() {
  QUnit.test("socketio can register", function(assert) {
    regSockio("test", "hello");

    //Has the correct name
    assert.equal(id_to_sockio["test"], "hello", "")
  });
});
