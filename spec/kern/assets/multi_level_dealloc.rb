controller :nav do
  spots "content"

  action :index do
    on_entry %{
      Embed("my_controller", "content", {});
    }

    on "next_nav", %{
      Goto("other_action");
    }
  end

  action :other_action do

  end
end

controller :my_controller do
  spots "content"

  action :my_action do
    on_entry %{
      my_controller_bp = __base__;
      Embed("other", "content", {});
    }

    on "next", %{
      Push("my_other_action")
    }
  end

  action :my_other_action do
    on_entry %{
      Embed("other2", "content", {});
    }

    on "back", %{
      Pop();
    }
  end
end

controller :other do
  services :test

  action :index do
    on_entry %{
      other_bp = __base__;
    }
  end
end

controller :other2 do
  services :test

  action :index do
    on_entry %{
      other_bp2 = __base__;
    }
  end
end

