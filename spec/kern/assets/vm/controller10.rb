controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var page = vm_create_page("test");

      var info = {
        ns: "spec",
        page: page
      };

      Request("vm", "write", info);
    }

    on "read_res", %{
    }
  end
end
