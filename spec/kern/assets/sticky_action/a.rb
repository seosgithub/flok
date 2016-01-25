controller :foo do
  spots "content", "extra"

  on_entry %{
      foo_base = __base__;
  }

  sticky_action :a do
    on_entry %{
      Embed("bar", "content", {});
      Embed("bar2", "extra", {});
    }

    on "next_clicked", %{
      Goto("b")
    }

    on "next2_clicked", %{
      Goto("c")
    }
  end

  action :b do
    on_entry %{
      Embed("hello", "content", {});
    }

    on "back_clicked", %{
      Goto("a");
    }
  end

  sticky_action :c do
    on_entry %{
      Embed("bar3", "content", {});
    }

    on "back_clicked", %{
      Goto("a");
    }
  end
end

controller :bar do
  action :index do
    on_entry %{
      bar_base = __base__;
    }

  end
end

controller :bar2 do
  action :index do
    on_entry %{
      bar2_base = __base__;
    }

  end
end

controller :bar3 do
  action :index do
    on_entry %{
      bar3_base = __base__;
    }

  end
end


controller :hello do
  action :index do
    on_entry %{
      hello_base = __base__;
    }

  end
end

