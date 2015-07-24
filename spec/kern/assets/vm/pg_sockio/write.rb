controller :my_controller do
  services :vm

  on_entry %{
    read_res_params = [];
  }

  action :my_action do
    on_entry %{
      var page = vm_create_page("test");

      var info = {
        ns: "sockio",
        page: page,
      };

      Request("vm", "write", info);
    }

    on "read_res", %{
      read_res_params.push(JSON.parse(JSON.stringify(params)));
    }
  end
end
