controller :my_controller do
  action :index do
    on_entry %{
      my_controller_base = __base__;
    }

    on "next_clicked", %{
      Goto("other");
    }

  end

  action :other do
    on_entry %{
      other_entered = true;
    }
  end
end
