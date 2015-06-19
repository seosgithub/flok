controller :my_controller do
  on_entry %{
    global_on_entry_called = true;
  }

  action :index do
  end
end
