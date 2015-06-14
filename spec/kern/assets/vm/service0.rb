service :my_service do
  on_wakeup %{
    on_wakeup_called = true; 
  }

  on_sleep %{
    on_sleep_called = true;
  }

  on_connect %{
    on_connect_called = true;
  }

  on_disconnect %{
    on_disconnect_called = true;
  }

  every 1.seconds, %{
    for (var i = 0; i < Object.keys(sessions).length; ++i) {
      var bp = Object.keys(sessions)[i];
      int_event(bp, "ping", {});
    }
  }
end
