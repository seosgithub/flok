controller :my_controller do
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
