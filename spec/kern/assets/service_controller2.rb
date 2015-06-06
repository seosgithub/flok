controller :my_controller do
  spots "hello", "world"

  action :my_action do
    on_entry %{
      Embed("my_other_controller", "hello", {});
    }

    on "next", %{
      Goto("my_other_action");
    }
  end

  action :my_other_action do
    on_entry %{
    }

    on "next", %{
      Goto("my_action");
    }
  end

end

controller :my_other_controller do
  services :spec

  action :my_action do
    on_entry %{
      my_base = __base__;
      var info = {
        hello: "world"
      }
      Request("spec", "ping", info);
    }
  end
end

