controller :my_controller do
  spots "hello", "world"

  on_entry %{
    my_action_entered_count = 0;
  }

  action :my_action do
    on_entry %{
      Embed("my_controller2", "hello", {});
      my_action_entered_count += 1;
    }

    on "test_event", %{
      Push("my_other_action")
    }
  end

  action :my_other_action do
    on_entry %{
      my_other_action_on_entry_called = true;
    }

    on "back", %{
      Pop();
    }
  end
end

controller :my_controller2 do
  action :my_action do
    on_entry %{
    }
  end
end
