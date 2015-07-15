controller :my_controller do
  spots "content"
  services "test"

  choose_action do
    on_entry %{
      var info = {foo: "bar"};
      Request("test", "test_async", info);
    }

    on "test_async_res", %{
      Goto("index");
    }
  end

  action "index" do
    on_entry %{
    }
  end

  action "alt" do
  end
end
