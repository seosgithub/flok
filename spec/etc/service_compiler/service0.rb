service :my_service do
  type :daemon

  on_wakeup %{
    on_wakeup_called = true;
  }

  on_sleep %{
    on_sleep_called = true;
  }

  on_connect %{
    on_connect_called_bp = bp;
  }

  on_disconnect %{
    on_disconnect_called_bp = bp;
  }

  on "hello", %{
    on_hello_called_bp = bp;
    on_hello_called_params = JSON.stringify(params);
  }

  every 5.seconds, %{
    on_every_5_sec_called = true;
  }
end
