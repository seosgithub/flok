controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var watch_info = {
        ns: "spec",
        id: "test"
      }

      Request("vm", "unwatch", watch_info);
      Request("vm", "unwatch", watch_info);
    }
  end
end
