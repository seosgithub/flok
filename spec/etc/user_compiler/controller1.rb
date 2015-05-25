controller :my_controller do
  spots "hello", "world"

  action :index do
    on_entry %{
    }
  end

  action :about do
    on_entry %{
    }
  end
end
