controller :my_controller do
  spots "hello", "world"

  on_entry %{
      every_025_called_count = 0;
      every_05_called_count = 0;
      every_1_called_count = 0;
  }

  action :my_action do
    on "next", %{
      Goto("other");
    }

    every (0.25).seconds, %{
      every_025_called_count += 1;
    }
  end
  
  action :other do
    every (0.5).seconds, %{
      every_05_called_count += 1;
    }

    every 1.seconds, %{
      every_1_called_count += 1;
    }

    on "back", %{
      Goto("my_action")
    }
  end
end
