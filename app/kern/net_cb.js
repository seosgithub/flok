//Network Callback Related

var tp_to_info = {};

function get_req(owner, url, params, callback) {
  //Even though it's the same function, create a tp because we need to track owner somehow.
  var tp = get_req_callback;
  tp_to_owner[tp] = {
    owner: owner,
    callback: callback
  };

  //Create request
  if_dispatch([4, "if_net_req", "GET", url, params, tp]);
}

function get_req_callback(tp, success, info) {
  var info = tp_to_info[tp];
  if (tel_exists(info.owner) === true) {
    info.callback(success, info);
  }

  tel_del(tp);
  remove tp_to_info[tp];
}
