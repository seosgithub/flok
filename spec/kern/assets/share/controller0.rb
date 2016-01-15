controller :foo do
  share :hello
  spots "content"

  action :index do
    on_entry %{
      Embed("bar", "content", {});
    }
  end
end

controller :bar do
  map_share :hello

  action :index do
    on_entry %{
    }
  end
end

