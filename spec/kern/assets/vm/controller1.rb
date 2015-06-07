controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var info = {
        ns: "user",
        key: "x"
      };

      Request("vm", "read_sync", info);
    }
  end
end
