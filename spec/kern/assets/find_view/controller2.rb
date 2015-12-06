controller :my_controller do
  spots "content"

  action :index do
    on_entry %{
      Embed("my_controller2", "content", {});

      find_view_res = find_view(__base__, {
        ".": {
           "__leaf__": "foo"
        }
      });
    }
  end
end

controller :my_controller2 do
  action :index do
    on_entry %{
      my_controller2_base = __base__;
    }
  end
end
