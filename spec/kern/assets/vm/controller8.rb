controller :my_controller do
  spots "content"
  services :vm

  action :my_action do
    on_entry %{
      //Send a request
      var info = {
        ns: "spec",
        id: "my_key"
      };

      Request("vm", "watch", info);
    }

    on "read_res", %{
    }
  end
end
