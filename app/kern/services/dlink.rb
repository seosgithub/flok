service :dlink do
  global %{
    //Static from the dlink module itself, this is a sister service
    function dlink_notify_handler(url, params) {
      //Notify all view controllers
      var cbps = Object.keys(dlink_sessions);
      var einfo = {url: url, params: params};
      for (var i = 0; i < cbps.length; ++i) {
        int_event_defer(parseInt(cbps[i]), "dlink_req", einfo);
      }
    }
  }

  on_wakeup %{
 }

  on_sleep %{
  }

  on_connect %{
  }

  on_disconnect %{
  }
end
