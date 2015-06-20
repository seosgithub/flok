service :my_service do
  global %{
    every_ticks = 0;
  }

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
    every_ticks += 1;
  }
end
