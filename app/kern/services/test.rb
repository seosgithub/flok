service :test do
  global %{
    function <%= @name %>_function(x) {
      <%= @name %>_function_args = x;
    }
  }

  on "test_sync", %{
    int_event(bp, "test_sync_res", params);
  }

  on "test_async", %{
    int_event_defer(bp, "test_async_res", params);
  }
end
