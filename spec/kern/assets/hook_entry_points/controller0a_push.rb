controller :my_controller do
  spots "hello", "world"

  macro :my_macro do
    on "foo", %{
    }

  end

  action :index do
    on_entry %{
      on_entry_base_pointer = __base__;
    }

    on "hello", %{
      var x = 3;
    }

    my_macro
  end

  action :other do
    on "test", %{
      Push("index");
    }

    on "holah", %{
      Pop();
    }
  end
end
