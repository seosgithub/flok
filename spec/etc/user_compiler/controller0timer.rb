controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      var x = 4;
    }

    every 3.seconds, %{
    }

    on "hello", %{
      var x = 3;
    }
  end
end
