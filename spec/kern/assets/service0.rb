service :my_service do
  on_wakeup %{
    on_wakeup_called = true; 
  }

  on_sleep %{
  }

  on_connect %{
    on_connect_called = true;
  }

  on_disconnect %{
    on_disconnect_called = true;
  }
end
