//Network Callback Related

function get_req(url, params, callback) {
  //Register callback
  var tp = tel_reg(function(success, info) {
    return callback(info);
  });

  //Create request
  if_dispatch([4, "if_net_req", "GET", url, params, tp]);
}
