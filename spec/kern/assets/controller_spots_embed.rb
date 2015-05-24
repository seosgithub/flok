controller :my_controller do
  view "my_view"
  spots "one", "two"

  action :index do
    on_entry %{
      Embed("my_other_controller", "one", {});
    }

    on "test1", %{
    }
  end
end

controller :my_other_controller do
  view "my_other_view"

  action :index do
    on_entry %{
    }

    on "test2", %{
    }
  end
end
