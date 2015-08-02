controller :my_controller do
  services :test

  on_entry %{
      var info = {
        foo: "bar"
      }
      Request("test", "test_async", info);
  }

  action :my_action do
    on_entry %{
    }

    on "test_async_res", %{
      test_async_res_params = params;
    }
  end
end
