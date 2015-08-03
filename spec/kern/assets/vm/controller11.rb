controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var page = vm_create_page("test");

      var watch_info = {
        ns: "spec",
        id: "test"
      }

      var write_info = {
        ns: "spec",
        page: page
      };

      Request("vm", "watch", watch_info);
      Request("vm", "write", write_info);
    }

    on "read_res", %{
      read_res_params = params;
    }
  end
end
