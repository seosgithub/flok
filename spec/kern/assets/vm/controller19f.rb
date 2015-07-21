controller :controller0 do
  services :vm
  spots "first", "second"

  action :index do
    on_entry %{
      //request page 'A' on frame0 of controller0
      var info = {
        ns: "spec",
        id: "A"
      }
      //get page A
      Request("vm", "read_sync", info);

      //embed controller1 & controler2
      Embed("controller1", "first", {});
      Embed("controller2", "second", {});
    }

    on "read_res", %{
      controller0_read_sync_res = params;
    }
  end
end

controller :controller1 do
  services :vm

  action :index do
    on_entry %{
      controller1_base = __base__;
    }

    #action is dispatched on frame1
    on "get", %{
      //request page 'A' on frame1 of controller1
      var info = {
        ns: "spec",
        id: "A"
      }
      //get page A (again, read from cache)
      Request("vm", "read_sync", info);
      throw "shit";
    }

    on "read_res", %{
      controller1_read_sync_res = params;
    }
  end
end

controller :controller2 do
  services :vm

  action :index do
    on_entry %{
      controller2_base = __base__;
    }

    #action is dispatched on frame1
    on "get", %{
      //request page 'B' on frame1 of controller2
      var info = {
        ns: "spec",
        id: "B"
      }

      //get page B
      Request("vm", "read_sync", info);
    }

    on "read_res", %{
      controller2_read_sync_res = params;
    }
  end
end
