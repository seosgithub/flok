controller :my_controller do
  spots "one", "two"

  action :index do
    on_entry %{
    }
  end
end
