controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      reg_timer(__base__, "tick", 1);
    }

    on "tick", %{
      did_tick = true;
    }
  end
end
