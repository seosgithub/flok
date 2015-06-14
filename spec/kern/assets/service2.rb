service :my_service do
  on_wakeup %{
  }

  on_sleep %{
  }

  on_connect %{
    connect_bp = bp;
    connect_sessions = Object.keys(sessions);
  }

  on_disconnect %{
    disconnect_bp = bp;
    disconnect_sessions = Object.keys(sessions);
  }

  every 1.seconds, %{
    every_ticks_sessions = Object.keys(sessions);
  }

  on "ping", %{
    ping_bp = bp;
    ping_params = params;
    ping_sessions = Object.keys(sessions);
  }
end
