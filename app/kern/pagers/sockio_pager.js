<% if @defines['sockio_pager'] %>
  sockio_pager_data = {};

  sockio_pager_sp = null;
  sockio_pager_bp = null;
  waiting_bp = null;
  function sockio_pager_init(options) {
    sockio_pager_sp = tels(1);
    sockio_pager_bp = tels(1);
    SEND("main", "if_sockio_init", options.url, sockio_pager_sp);
    reg_evt(sockio_pager_bp, sockio_pager_sp_endpoint);
    SEND("net", "if_sockio_fwd", sockio_pager_sp, "read_res", sockio_pager_bp);
  }

  function sockio_pager_read_sync(ns, bp, key) {
    throw "sockio_pager does not support read_sync"
  }

  function sockio_pager_read(ns, bp, key) {
    var info = {
      key: key,
      bp: bp
    }

    SEND("net", "if_sockio_send", sockio_pager_sp, "read", info);

    waiting_bp = bp;
  }

  function sockio_pager_write(key, value) {
    throw "sockio_pager does not support write"
  }

  //Where socket.io data comes in
  function sockio_pager_sp_endpoint(ep, ename, info) {
    var bp = info.bp;
    var key = info.key;
    var value = info.value;
    int_event(waiting_bp, "read_res", info);
  }
<% end %>
