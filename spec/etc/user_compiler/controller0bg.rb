controller :my_controller do
  spots "hello", "world"

  on_entry %{
    global_on_entry = true;
  }

  action :my_action do
    on "hello", %{
      var x = 3;
    }
  end
end
