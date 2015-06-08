controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      //Send a request
      var info = {
        ns: "user",
        key: "my_key",
        value: "my_value"
      };

      read_res_called_with = [];
      Request("vm", "read", info);
      Request("vm", "read", info);
    }

    on "read_res", %{
      read_res_called_with.push(params);
    }
  end
end
