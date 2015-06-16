controller :my_controller do
  action :my_action do
    on_entry %{
      //Queue up a deferred event
      int_event_defer(__base__, "defer_res", {foo: "bar"});

      int_event(__base__, "sync_res", {foo_sync: "bar"});
    }

    on "defer_res", %{
      defer_res_params = params;
    }

    on "sync_res", %{
      sync_res_params = params;
    }
  end
end
