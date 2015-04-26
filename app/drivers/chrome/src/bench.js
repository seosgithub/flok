function bench() {
  for (var i = 0; i < 100; ++i) {
    owner = tel_reg(true);
    get_req(owner, "http://test.services.fittr.com/ping", {}, function(info) {
    });
  }
}
