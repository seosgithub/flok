controller :my_controller do
  action :index do
    on_entry %{
      on_entry_base_pointer = __base__;
    }

    on "next_clicked", %{
      Push("other")
    }

  end

  action :other do
  end
end
