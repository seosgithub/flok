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

      var info2 = {
        ns: "spec",
        id: "test2"
      }

      //requesting 'test' and 'test2'
      Request("vm", "read_sync", info);
      Request("vm", "read_sync", info2);
    }

    on "read_res", %{
      read_sync_res_params.push(params);
    }
  end
end
