controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      on_entry_base_pointer = __base__;
    }

    on "hello", %{
      Send("test_event", params);
    }
  end
end
