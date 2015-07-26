controller :my_controller do
  services :test
  spots "content"

  action :my_action do
    on_entry %{
      Embed("other", "content", {});
    }

    on "next", %{
      Goto("my_other_action")
    }
  end

  action :my_other_action do
    on_entry %{
      Embed("other2", "content", {});
    }
  end
end

controller :other do
  services :test

  action :index do
    on_entry %{
      other_bp = __base__;
      kern_log("My bp is: " + __base__)
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

