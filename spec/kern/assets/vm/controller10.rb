controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      
      //Send a request
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
