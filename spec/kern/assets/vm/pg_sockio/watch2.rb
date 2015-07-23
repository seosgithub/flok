controller :my_controller do
  services :vm

  on_entry %{
    read_res_params = [];
  }

  action :my_action do
    on_entry %{
      var watch_info = {
        ns: "sockio",
        id: "test", 
      };

      Request("vm", "watch", watch_info);
    }

    on "read_res", %{
      read_res_params.push(JSON.parse(JSON.stringify(params)));
    }
  end
end
