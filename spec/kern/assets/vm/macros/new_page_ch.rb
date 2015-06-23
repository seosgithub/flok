controller :controller do
  action :index do
    on_entry %{
      page = NewPage("hash");
    }
  end
end
