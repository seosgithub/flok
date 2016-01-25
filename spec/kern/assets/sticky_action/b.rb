controller :foo do
  spots "content"

  on_entry %{
    foo_base = __base__;
  }
  
  action :index do
    on_entry %{
      Embed("bar", "content", {});
    }

    on "next_clicked", %{
      Goto("about")
    }
  end

  action :about do
  end
end

controller :bar do
  spots "content"

  on_entry %{
    bar_base = __base__;
  }

  action :index do
    on_entry %{
    }

    on "next_clicked", %{
      Goto("about");
    }
  end

  sticky_action :about do
    on_entry %{
      Embed("hello", "content", {});
    }

    on "back_clicked", %{
      Goto("index");
    }
  end
end

controller :hello do

  on_entry %{
    hello_base = __base__;
  }

  action :shit do
    on_entry %{
    }
  end
end
