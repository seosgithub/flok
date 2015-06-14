service :test do
  on_wakeup %{
    test_service_var = true;
  }

  on_sleep %{
  }

  on_connect %{
  }

  on_disconnect %{
  }

  on_event "hello", %{
  }

  every 5.seconds, %{
  }
end
