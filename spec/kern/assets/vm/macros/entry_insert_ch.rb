controller :controller do
  action :index do
    on_entry %{
      original_page = {
        _head: "head",
        _next: "next",
        _id: "id",
        entries: {
          "id0": {"_sig": "sig0"},
          "id1": {"_sig": "sig1"},
        },
        _hash: "hash",
        _type: "hash",
      };

      page = CopyPage(original_page);
      var entry0 = {hello: "world"}
      var entry2 = {hello: "world2"}
      EntryInsert(page, "id0", entry0);
      EntryInsert(page, "id2", entry2);
    }
  end
end
