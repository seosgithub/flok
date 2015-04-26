//Network Callback Related

function get_req(owner, url, params, callback) {
  //Register callback, we need a copy of tp
  //This function encloses
  (function() {
    var tp = tel_reg(function(success, info) {
      //Only let a callback go through if the owner still exists
      if (tel_exists(owner) === true) {
        return callback(info);
      }

      tel_del(tp);
    });
    //Create request
    if_dispatch([4, "if_net_req", "GET", url, params, tp]);
  })();
}
