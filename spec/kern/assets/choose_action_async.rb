controller :my_controller do
  spots "content"
  services "test"

  choose_action do
    on_entry %{
      var info = {foo: "bar"};
      Request("test", "test_async", info);
    }

    #This is illegal, we are testing for an exception. All
    #events received in choose_action must be synchronous
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
