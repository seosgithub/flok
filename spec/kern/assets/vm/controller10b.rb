controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var rd_info = {
        ns: "spec",
        id: "test",
      };
      Request("vm", "read_sync", rd_info);
    }

    on "read_res", %{
      var page = vm_create_page("test");
      var wr_info = {
        ns: "spec",
        page: page
      };

      Request("vm", "write", wr_info);
    }
  end
end
