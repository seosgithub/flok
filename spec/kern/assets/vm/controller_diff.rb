controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var info = {
        ns: "spec0",
        id: "test",
        diff: true
      }

      Request("vm", "watch", info);
    }
  end
end
