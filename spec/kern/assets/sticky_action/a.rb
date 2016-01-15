controller :foo do
  spots "content"
  sticky_action :a do
    on_entry %{
      foo_base = __base__;
      Embed("bar", "content", {});
    }
    on "next_clicked", %{
      Goto("b")
    }
  end

  action :b do
  end
end

controller :bar do
  action :index do

  end
end
