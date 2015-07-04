controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      //Write a page
      var page = NewPage("array", "test");
      var entry = {value: 4}
      EntryInsert(page, 0, entry);
      var info = {ns: "spec0", page: page};
      Request("vm", "write", info);

      var info = {
        ns: "spec0",
        id: "test",
        diff: true
      }

      Request("vm", "watch", info);
    }

    on "read_res", %{
      context.page = params;

      _read_res_page = params;
    }

    on "modify", %{
      var page = context.page;
      page = CopyPage(page);

      var e = EntryMutable(page, 0);
      e.value = 5;
      var info = {ns: "spec0", page: page};
      Request("vm", "write", info);
    }

    on "entry_modified", %{
      entry_modified_params = params;
    }
  end
end
