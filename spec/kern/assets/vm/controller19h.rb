controller :my_controller do
  services :vm

  on_entry %{
    read_sync_res_params = [];
  }

  action :my_action do
    on_entry %{
      var info = {
        ns: "spec",
        id: "test"
      }

      Request("vm", "read_sync", info);
    }

    on "read_res", %{
      read_sync_res_params.push(params);
    }
  end
end

