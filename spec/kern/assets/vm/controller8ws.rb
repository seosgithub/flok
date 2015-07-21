controller :my_controller do
  spots "content"
  services :vm

  on_entry %{
      read_res_params = [];
  }

  action :my_action do
    on_entry %{
      page0 = {
        ns: "spec",
        id: "my_key",
        sync: true
      };

      Request("vm", "watch", page0);
    }

    on "read_res", %{
      read_res_params.push(params);
    }
  end
end

