controller :foo do
  share_spot :content
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
      Goto("other");
    }
  end
  action :other do
  end
end

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
