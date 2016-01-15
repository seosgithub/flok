controller :foo do
  share :user
  spots "content"

  action :index do
    on_entry %{
      Embed("re", "content", {});
      shared.user.uid = "foo"
      foo_shared_user = shared.user;
    }
  end
end

controller :re do
  spots "content"

  action :index do
    on_entry %{
      Embed("bar", "content", {});
    }
  end
end


controller :bar do
  map_share :user

  action :index do
    on_entry %{
      bar_shared_user = shared.user;
    }
  end
end

