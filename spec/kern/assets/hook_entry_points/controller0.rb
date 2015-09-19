controller :my_controller do
  spots "hello", "world"

  action :index do
    on_entry %{
      on_entry_base_pointer = __base__;
    }

    on "hello", %{
      var x = 3;
    }
  end
end
