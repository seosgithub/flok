controller :controller do
  action :index do
    on_entry %{
      page = NewPage();
    }
  end
end
