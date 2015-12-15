controller :my_controller do
  services :rest

  action :my_action do
    on_entry %{
      var info = {
        path: "test",
        params: {"hello": "world"}
      }
      Request("rest", "get", info);
    }

    on "rest_res", %{
      rest_res_params = params;
    }
  end
end

controller :my_controller2 do
  action :my_action do
  end
end


controller :root_controller do
  spots "content"

  on_entry %{
    root_base = __base__;
  }

  action :action_a do
    on_entry %{
      Embed("my_controller", "content", {});
    }

    on "next_clicked", %{
      Goto("action_b")
    }
  end

  action :action_b do
    on_entry %{
      Embed("my_controller2", "content", {});
    }
  end
end
