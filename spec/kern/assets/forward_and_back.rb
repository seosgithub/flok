controller :fabric do
  spots "content"

  action "one" do
    on_entry %{
      Embed("one", "content", {});
    }

    on "next_clicked", %{
      Goto("two");
    }
  end

  action "two" do
    on_entry %{
      Embed("two", "content", {});
    }

    on "back_clicked", %{
      Goto("one");
    }
  end
end

controller :one do
  action "index" do
    on_entry %{
    }
  end
end

controller :two do
  action "index" do
    on_entry %{
    }
  end
end
