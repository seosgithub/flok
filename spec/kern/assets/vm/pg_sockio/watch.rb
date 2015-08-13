controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var watch_info = { ns: "sockio", id: "test", };
      Request("vm", "watch", watch_info);
    }

    on "read_res", %{
      read_res_params = params;
    }

    on "unwatch", %{
      var unwatch_info = { ns: "sockio", id: "test"};
      Request("vm", "unwatch", unwatch_info);
    }
  end
end
