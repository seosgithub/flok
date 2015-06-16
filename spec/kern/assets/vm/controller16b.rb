controller :my_controller do
  spots "content"

  action :a do

    on_entry %{
      Embed("a", "content", {});
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
    }
  end
end
