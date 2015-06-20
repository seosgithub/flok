controller :my_controller do
  spots "content"

  on_entry %{
    timer_called = 0;
  }

  action :my_action do
    on_entry %{
      Embed("alt1", "content", {});
    }

    on "next", %{
      Goto("other");
    }
  end
  
  action :other do
    on_entry %{
    }
      
    on "back", %{
      Goto("my_action")
    }
  end
end

controller :alt1 do

  action :index do
    on_entry %{
    }

    every (0.25).seconds, %{
      timer_called += 1;
    }

  end
end
