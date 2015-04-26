res = []
function bench() {
  for (var i = 0; i < 1000; ++i) {
    var owner = tel_reg(true);
    startRequest(owner);
  }
}

function startRequest(owner) {
  get_req(owner, "http://test.services.fittr.com/ping", {}, function(info) {
    res.push(info);
    tel_del(owner);
  });
}
