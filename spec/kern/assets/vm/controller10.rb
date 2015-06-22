controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var entry = {
        hello: "world"
      }

      page = NewPage("array", "test");
      SetPageHead(page, "head");
      SetPageNext(page, "next");
      EntryInsert(page, 0, entry);

      var info = {
        ns: "spec",
        page: page
      };

      Request("vm", "write", info);
    }

    on "read_res", %{
    }
  end
end
