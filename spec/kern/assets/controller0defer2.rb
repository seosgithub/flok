controller :my_controller do
  action :my_action do
    on_entry %{
      //Queue up a deferred event
      int_event_defer(__base__, "defer_res", {foo: "bar"});
      int_event_defer(__base__, "defer_res2", {foo: "bar"});
    }

    on "defer_res", %{
      defer_res_params = params;
    }

    on "defer_res2", %{
      defer_res2_params = params;
    }
  end
end
