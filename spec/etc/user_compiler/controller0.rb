controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      var x = 4;
    }

    on "hello", %{
      var x = 3;
    }
  end
end
