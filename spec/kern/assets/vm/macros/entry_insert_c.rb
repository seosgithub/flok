controller :controller do
  action :index do
    on_entry %{
      original_page = {
        _head: "head",
        _next: "next",
        _id: "id",
        entries: [
          {_id: "id", _sig: "sig"},
        ],
        _hash: "hash",
      };

      page = CopyPage(original_page);
      var entry0 = {hello: "world"}
      var entry2 = {hello: "world2"}
      EntryInsert(page, 0, entry0);
      EntryInsert(page, 2, entry2);
    }
  end
end
