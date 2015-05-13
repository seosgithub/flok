controller :my_controller do
  view :test_view
  spots "hello", "world"

  action :my_action do
    on_entry %{
    }

    on "start_request", %{
      ServiceRequest("rest", info, "request_response");
    }

    on "request_response", %{
    }
  end
end
