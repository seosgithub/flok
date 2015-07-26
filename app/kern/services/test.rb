service :test do
  global %{
    test_service_connected = {};

    function <%= @name %>_function(x) {
      <%= @name %>_function_args = x;
    }
  }

  on_connect %{
    test_service_connected[bp] = true;
  }

  on_disconnect %{
    delete test_service_connected[bp];
  }

  on "test_sync", %{
    int_event(bp, "test_sync_res", params);
  }

  on "test_async", %{
    int_event_defer(bp, "test_async_res", params);
  }
end
