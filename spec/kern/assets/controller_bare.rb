controller :my_controller do
  view "my_view"

  action :index do
    on_entry %{
    }

    on "test", %{
    }
  end
end
