controller :my_controller do
  services :dlink

  on_entry %{
    dlink_res_params = null;
  }

  action :my_action do
    on_entry %{
    }

    on "dlink_req", %{
      dlink_res_params = params;
    }
  end
end
