controller :my_controller do
  services :test

  action :my_action do
    on_entry %{
      my_action_entered = true;
    }
  end
end
