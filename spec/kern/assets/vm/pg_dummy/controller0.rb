controller :my_controller do
  services :vm

  action :my_action do
    on "do_write", %{
      var page = vm_create_page("lol");

      //Cheat and put the page in
      vm_cache["dummy"]["lol"] = page;

      var info = {
        ns: "dummy",
        page: page
      }
      Request("vm", "write", info);
    }
  end
end
