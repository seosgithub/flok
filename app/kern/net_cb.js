//Network Callback Related

var tp_to_info = {};

function get_req(owner, url, params, callback) {
  //Even though it's the same function, create a tp because we need to track owner somehow.
  var tp = tel_reg(get_req_callback);
  tp_to_info[tp] = {
    owner: owner,
    callback: callback
  };

  //Create request
  if_dispatch([4, "if_net_req", "GET", url, params, tp]);
}

function get_req_callback(tp, success, info) {
  var _info = tp_to_info[tp];
  if (tel_exists(_info.owner) === true) {
    _info.callback(info);
  }

  tel_del(tp);
  delete tp_to_info[tp];
}
