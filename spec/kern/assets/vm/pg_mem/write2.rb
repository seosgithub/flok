controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      var entry = {
        hello: "world"
      }

      var entry2 = {
        hello: "world"
      }


      page = NewPage("array", "test");
      SetPageHead(page, "head");
      SetPageNext(page, "next");
      EntryInsert(page, 0, entry);

      var write_info = {
        ns: "local0",
        page: page
      };

      page2 = CopyPage(page);
      EntryInsert(page2, 0, entry);

      var write_info2 = {
        ns: "local1",
        page: page2
      };


      Request("vm", "write", write_info);
      Request("vm", "write", write_info2);
    }
  end
end
