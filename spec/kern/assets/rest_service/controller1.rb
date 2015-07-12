controller :my_controller do
  services :rest

  action :my_action do
    on_entry %{
      var info = {
        path: "test",
        params: {"hello": "world"}
      }
      Request("rest", "get", info);
    }

    on "rest_res", %{
      rest_res_params = params;
    }
  end
end
