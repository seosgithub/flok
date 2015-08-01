controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      page = vm_create_page("test");

      var write_info = {
        ns: "local",
        page: page
      };

      Request("vm", "write", write_info);
      kern_log("hey");
    }
  end
end
