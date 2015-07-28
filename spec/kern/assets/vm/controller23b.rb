controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      //Page to write
      var page = vm_create_page("test");

      //Dispatch write request
      var info = {
        ns: "dummy",
        page: page
      }
      Request("vm", "write", info);
      Request("vm", "write", info);
    }
  end
end
