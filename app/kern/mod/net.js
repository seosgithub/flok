function int_net_cb(tp, success, info) {
  tel_deref(tp)(success, info);
}

//Spec helpers
/////////////////////////////////////////////////////
function get_int_net_cb_spec() {
  if_dispatch([0, int_net_cb_spec])
}

//Manually register pointer at special index for testing, int_net_cb
//will call this pointer under test conditions so it's a good test
//for bost telepathy and net
tel_reg_ptr(function(a, b) { int_net_cb_spec = [a, b] }, -3209284741);
/////////////////////////////////////////////////////
