controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var info = {
        ns: "user",
        key: 33
      };

      Request("vm", "read", info);
    }

    on "read_res", %{
      read_res_params = params;
    }
  end
end
