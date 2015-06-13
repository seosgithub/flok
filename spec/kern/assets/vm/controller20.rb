controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var watch_info = {
        ns: "spec",
        id: "hello"
      }

      read_res = [];
      Request("vm", "watch", watch_info);
    }

    on "read_res", %{
      read_res.push(params);
    }
  end
end
