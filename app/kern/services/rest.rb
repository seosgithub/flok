service :rest do
  global %{
    rest_in_flight = {}

    function rest_cb(tp, code, info) {
      var e = rest_in_flight[tp];
      var bp = e[0];
      var path = e[1];

      int_event(bp, "rest_res", {
        path: path,
        code: code,
        res: info
      });

      tel_del(tp);
    }
  }

  on_wakeup %{
  }

  on_sleep %{
  }

  on_connect %{
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
    rest_in_flight[tp] = [bp, params.path];
    SEND("net", "if_net_req", "GET", "<%= @options[:base_url] %>"+params.path, params.params, tp);
  }

  on_disconnect %{
  }
end
