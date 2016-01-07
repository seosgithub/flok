controller :my_controller do
  spots "content"
  services :vm

  action :a do
    on_entry %{
      Embed("a", "content", {});

      var info = {ns: "spec", id: "test"};
      Request("vm", "watch", info);
    }

    on "next", %{
      Goto("b");
    }
  end

  action :b do
    on_entry %{
    }
  end
end

controller :a do
  services :vm
  action :index do
    on_entry %{
      var info = {ns: "spec", id: "test"}
      Request("vm", "watch", info);
    }
  end
end
