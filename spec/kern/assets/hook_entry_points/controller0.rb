controller :my_controller do
  spots "hello", "world"

  macro :my_macro do
    on "foo", %{
    }

  end

  action :index do
    on_entry %{
      on_entry_base_pointer = __base__;
      Embed("my_other_controller", "hello", {});
    }

    on "hello", %{
      Goto("other");
    }

    my_macro
  end

  action :other do
    on_entry %{
      Embed("new_controller", "hello", {});
    }

    on "test", %{
    }
  end
end

controller :my_other_controller do
  action :index do
    on_entry %{
      my_other_controller_base = __base__;
    }

    on "back_clicked", %{
      Goto("other");
    }
  end

  action :other do
    on "next_clicked", %{
      Goto("other2");
    }
  end

  action :other2 do
    on "next_clicked", %{
      Goto("has_back_also");
    }
  end


  action :has_back_also do
    on "back_clicked", %{
      Goto("other");
    }
  end
end

controller :new_controller do
  action :index do
    on_entry %{
      new_controller_base = __base__;
    }
  end
end
