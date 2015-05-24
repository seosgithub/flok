controller :my_controller do
  spots "one", "two"

  action :index do
    on_entry %{
      Embed("my_other_controller", "one", {});
    }

    on "next", %{
      Goto("other");
    }
  end

  action :other do
    on_entry %{
    }
  end
end

controller :my_other_controller do
  action :index do
    on_entry %{
    }
  end
end
