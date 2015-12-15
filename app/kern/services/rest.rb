service :rest do
  global %{
    function rest_cb(tp, code, info) {
      var e = rest_pending_requests[tp];
      var bp = e.bp;
      var path = e.path;

      int_event(bp, "rest_res", {
        path: path,
        code: code,
        res: info
      });

      tel_del(tp);

      if (code > 0) {
        delete rest_pending_requests[tp];
        delete rest_bp_to_tps[bp][tp];
      } else {
        failed_requests_tp.push(tp);
      }
    }

    function rest_retry_failed() {
      for (var i = 0; i < failed_requests_tp.length; ++i) {
        var old_tp = failed_requests_tp[i];
        var info = rest_pending_requests[old_tp];

        if (info != null) {
          //Make a new telepointer as old is no longer valid to net driver
          var tp = tel_reg(rest_cb);
          SEND("net", "if_net_req", info.verb, info.url, info.params, tp);

          //Swap them out
          rest_pending_requests[tp] = info;
          rest_bp_to_tps[info.bp][tp] = true;
          delete rest_pending_requests[old_tp];
          delete rest_bp_to_tps[info.bp][old_tp];
        }
      }

      failed_requests_tp = [];
    }

    //Maps tp into enough information to make a request
    var rest_pending_requests = {};

    //Maps base-pointer into listing of current tele-pointers (disguised as an always true set for easy lookup)
    //for that controller [Int:[Int:Bool]]
    var rest_bp_to_tps = {};

    var failed_requests_tp = [];
  }

  on_wakeup %{
  }

  on_sleep %{
  }

  on_connect %{
    rest_bp_to_tps[bp] = [];
  }

  on "get", %{
    <% if @debug %>
      if (params.path === undefined) {
        throw "rest_service, no path given in get request";
      }

      if (params.params === undefined) {
        throw "rest_service, no params given in get request";
      }
    <% end %>

    var tp = tel_reg(rest_cb);
    rest_bp_to_tps[bp].push(tp);
    var url = "<%= @options[:base_url] %>"+params.path;

    SEND("net", "if_net_req", "GET", url, params.params, tp);

    rest_pending_requests[tp] = {
      verb: "GET",
      url: url,
      params: params.params,
      path: params.path,
      bp: bp,
    }
  }

  on_disconnect %{
    //Get all active tele-pointers for this view and destroy them
    //so we don't retry network requests
    var tps = Object.keys(rest_bp_to_tps[bp]);
    for (var i = 0; i < tps.length; ++i) {
      delete rest_pending_requests[tps[i]];
    }
    delete rest_bp_to_tps[bp];
  }

  every 2.seconds, %{
    //Re-try failed requests
    rest_retry_failed();
  }
end
