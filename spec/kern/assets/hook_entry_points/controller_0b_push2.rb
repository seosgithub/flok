controller :my_controller do
  spots "content"

  action :index do
    on_entry %{
      on_entry_base_pointer = __base__;
      Embed("my_controller2", "content", {});
    }

    on "next_clicked", %{
      Push("other")
    }

  end

  action :other do
    on_entry %{
      Embed("my_controller3", "content", {});
    }
  end
end

controller :my_controller2 do
  action :index do
    on_entry %{
      on_entry_base_pointer2 = __base__;
    }

    on "next_clicked", %{
      Push("other2")
    }

    on "olah", %{
    }

  end

  action :other2 do
    on "test", %{
    }

    on "next_clicked", %{
      Push("index")
    }
  end
end


controller :my_controller3 do
  action :index do
    on_entry %{
      my_controller3_base = __base__;
    }
  end
end
