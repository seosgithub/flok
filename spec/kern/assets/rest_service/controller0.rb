controller :my_controller do
  services :rest

  action :my_action do
    on_entry %{
    }
  end
end
