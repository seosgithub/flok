controller :foo do
  share_spot :content => :content
  spots "content"

  action :index do
    on_entry %{
      foo_base = __base__;
      Embed("bar", "content", {});
    }

  end

end

controller :bar do
  spots "content"
  action :index do
    on_entry %{
      bar_base = __base__;
      Embed("bar2", "content", {});
    }

    on "next_clicked", %{
      Push("other");
    }

    on "next2_clicked", %{
      Goto("other");
    }
  end

  action :other do
    on_entry %{
      Embed("hello2", "content", {});
    }
    on "back_clicked", %{
      Pop();
    }
  end
end
#Should receieve no more frees

controller :bar2 do
  map_shared_spot :content
  action :index do
    on_entry %{
      bar2_base = __base__;
      Embed("hello", "content", {});
    }
  end
end



controller :hello do
  action :index do
    on_entry %{
      hello_bp = __base__;
    }
  end
end

controller :hello2 do
  action :index do
    on_entry %{
      hello2_bp = __base__;
    }
  end
end

