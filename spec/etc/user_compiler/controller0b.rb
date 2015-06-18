controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on "hello", %{
      var x = 3;
    }
  end
end
