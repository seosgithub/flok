controller :my_controller do
  spots "one", "two"

  action :index do
    on_entry %{
      Embed("my_other_controller", "one", {});
    }

    on "next", %{
      Goto("other");
    }

    on "test1", %{
    }
  end

  action :other do
    on_entry %{
    }

    on "test2", %{
    }
  end
end

controller :my_other_controller do
  action :index do
    on_entry %{
    }

    on "test3", %{
    }
  end
end
