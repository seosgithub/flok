controller :my_controller do
  spots "content"
  services "test"

  choose_action do
    on_entry %{
      var info = {foo: "bar"};
      Request("test", "test_sync", info);
    }

    on "test_sync_res", %{
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
