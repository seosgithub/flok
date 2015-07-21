#Multiple controllers making a sync_read request of two different pages
#Not that the same page wouldn't trigger two sync reads, (because it will),
#but because we want to avoid any issues in the future.
controller :my_controller do
  services :vm
  spots "content"

  on_entry %{
  }

  action :my_action do
    on_entry %{
      var info = {
        ns: "spec",
        id: "test1"
      }

      //request page with id:test1
      Request("vm", "read_sync", info);

      Embed("my_other_controller", "content", {});
    }

    on "read_res", %{
      my_controller_read_sync_res = params;
    }
  end
end

controller :my_other_controller do
  services :vm

  on_entry %{
  }

  action :my_action do
    on_entry %{
      var info = {
        ns: "spec",
        id: "test2"
      }

      //request page with id:test2
      Request("vm", "read_sync", info);
    }

    on "read_res", %{
      my_other_controller_read_sync_res = params;
    }
  end
end
