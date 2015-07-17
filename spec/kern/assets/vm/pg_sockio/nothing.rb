controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
    }

    on "read_res", %{
      read_res_params = params;
    }
  end
end
