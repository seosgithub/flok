controller :my_controller do
  spots "content"

  action :index do
    on_entry %{
      Embed("my_controller2", "content", {});

      find_view(__base__, {});
    }
  end
end

controller :my_controller2 do
  action :index do
    on_entry %{
    }
  end
end

