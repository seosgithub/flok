//Network Callback Related

function get_request(url, params, callback) {
  //Register callback
  var tp = tel_reg(callback);

  //Create request
  if_request([4, "if_net_req", "GET", url, params, tp]);
}
