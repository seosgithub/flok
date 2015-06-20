controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      on_entry_base_pointer = __base__;
      every_025_called_count = 0;
      every_05_called_count = 0;
      every_1_called_count = 0;
    }

    on "hello", %{
      var x = 3;
    }

    every (0.25).seconds, %{
      every_025_called_count += 1;
      Send("025_message", {});
    }

    every (0.5).seconds, %{
      every_05_called_count += 1;
    }

    every 1.seconds, %{
      every_1_called_count += 1;
    }
  end
end
