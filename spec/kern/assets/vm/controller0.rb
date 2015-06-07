controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
    }
  end
end
