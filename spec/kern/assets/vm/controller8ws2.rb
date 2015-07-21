controller :my_controller do
  spots "content"
  services :vm

  on_entry %{
      read_res_params = [];
  }

  action :my_action do
    on_entry %{
      page0 = {
        ns: "spec",
        id: "my_key",
        sync: true
      };

      Request("vm", "watch", page0);
    }

    on "read_res", %{
      read_res_params.push(params);
    }
  end
end

controller :my_other_controller do
  services "vm"

  action :index do
    #Make changes to page, read_res should be called a second
    #time (asynchronously)
    on "modify_page", %{
      var p = vm_create_page("my_key");
      p.entries.push({
        _id: "test",
        _sig: "test",
        value: "test"
      });
      var info = {
        ns: "spec",
        page: p
      }
      Request("vm", "write", info);
    }
  end
end
