controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var entry = {
        hello: "world"
      }

      page = NewPage("test");

      SetPageHead(page, "head");
      SetPageNext(page, "next");
      EntryInsert(page, 0, entry);


      var watch_info = {
        ns: "spec",
        id: "test"
      }

      var write_info = {
        ns: "spec",
        page: page
      };

      Request("vm", "write", write_info);
    }

    on "next", %{
      page2 = CopyPage(page);
      SetPageHead(page2, "head2");
      var write_info = {
        ns: "spec",
        page: page2
      };
      Request("vm", "write", write_info);
    }
  end
end
