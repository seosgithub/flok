//Tests whether dlink_init will transmit the correct information

QUnit.test("dlink_init does notify the dlink system with the proper address", function(assert) {
  var done = assert.async();

  //Hijack the int event function
  window.int_dispatch = function(q) {
    int_dispatch_res = q;
  }

  dlink_init();

  assert.equal(JSON.stringify(int_dispatch_res), JSON.stringify([2, "int_dlink_notify", "http://test.com:80/test", {"foo": "bar"}]), "Matches");
  done();
});
