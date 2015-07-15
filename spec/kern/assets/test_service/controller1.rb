controller :my_controller do
  services :test

  action :my_action do
    on_entry %{
      var info = {
        foo: "bar"
      }
      Request("test", "test_sync", info);
    }

    on "test_sync_res", %{
      test_sync_res_params = params;
    }
  end
end
