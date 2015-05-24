controller :my_controller do
  view "my_view"
  spots "one", "two"

  action :index do
    on_entry %{
    }

    on "test", %{
    }

    on "test2", %{
    }
  end
end
