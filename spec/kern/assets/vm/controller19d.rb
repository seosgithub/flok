controller :my_controller do
  services :vm

  on_entry %{
  }

  action :my_action do
    on_entry %{
      var info = {
        ns: "spec",
        id: "test"
      }

      Request("vm", "read_sync", info);
    }

    on "read_sync_res", %{
      Goto("other");
    }
  end

  action :other do
    on_entry %{
    }

    on "get_test", %{
      //Second request should not trigger disk read as by this point, the cache would have been written
      var infox = {
        ns: "spec",
        id: "test"
      }
      Request("vm", "read_sync", infox);
    }
  end
end
