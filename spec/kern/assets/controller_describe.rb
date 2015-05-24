controller :my_controller do
  action :index do
    on_entry %{
      context.hello = 'world';
    }

    on "test", %{
    }
  end
end
