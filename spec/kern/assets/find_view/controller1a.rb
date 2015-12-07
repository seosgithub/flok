controller :my_controller do
  spots "content", "alt"

  action :index do
    on_entry %{
      Embed("my_controller2", "content", {});

      find_view_res = find_view(__base__, {
        "my_controller2": {
           "__leaf__": "foo",
           "my_controller3": {
             "__leaf__": "foo2"
           }
        },
      });
    }
  end
end

controller :my_controller2 do
  spots "content"

  action :index do
    on_entry %{
      my_controller2_base = __base__;
      Embed("my_controller3", "content", {});
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
