res = []
function bench() {
  for (var i = 0; i < 3000; ++i) {
    var owner = tel_reg(true);
    startRequest(owner);
  }
}

function startRequest(owner) {
  get_req(owner, "http://api.randomuser.me/", {}, function(info) {
    console.log(info);
    res.push(info);
    var url = info.results[0].user.picture.thumbnail;
    $("body").append("<img class='box' src='" + url + "' />");
    tel_del(owner);
  });

  int_dispatch(0, "ping");
}
