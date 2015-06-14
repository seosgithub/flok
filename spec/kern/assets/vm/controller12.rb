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

      page2 = CopyPage(page)
      EntryInsert(page, 0, entry);


      var watch_info = {
        ns: "spec",
        id: "test"
      }

      var write_info = {
        ns: "spec",
        page: page
      };

      var write_info2 = {
        ns: "spec",
        page: page2
      };


      read_res_params = [];
      Request("vm", "write", write_info);
      Request("vm", "watch", watch_info);
      Request("vm", "write", write_info2);
    }

    on "read_res", %{
      read_res_params.push(params);
    }
  end
end
