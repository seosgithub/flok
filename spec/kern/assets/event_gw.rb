controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      Embed("my_sub_controller", "hello", context);
    }
  end
end

controller :my_sub_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      sub_event_gw = __info__.event_gw;
    }
  end
end
