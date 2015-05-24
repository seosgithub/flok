controller :my_controller do
  spots "content"

  macro :my_macro do
    on "test_event", %{
      Goto("my_other_action")
    }
  end

  action :my_action do
    my_macro

    on_entry %{
    }
  end

  action :my_other_action do
    on_entry %{
    }
  end
end
