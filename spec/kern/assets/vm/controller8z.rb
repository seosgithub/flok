controller :my_controller do
  spots "content"
  services :vm

  action :my_action do
    on_entry %{
      page0 = {
        ns: "spec",
        id: "my_key"
      };

      Request("vm", "watch", page0);
    }

    on "read_res", %{
    }
  end
end

controller :my_controller_sync do
  spots "content"
  services :vm

  action :my_action do
    on_entry %{
      page = {
        ns: "spec",
        id: "my_key",
      };

      Request("vm", "watch", page);
    }

    on "read_res", %{
    }
  end
end
