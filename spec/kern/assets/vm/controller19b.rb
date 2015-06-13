controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var watch_info = {
        ns: "spec",
        id: "test",
        sync: true
      }

      Request("vm", "watch", watch_info);
    }
  end
end
