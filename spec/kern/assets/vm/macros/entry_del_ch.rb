controller :controller do
  action :index do
    on_entry %{
      original_page = {
        _head: "head",
        _next: "next",
        _id: "id",
        entries: {
          "id0": {_sig: "sig"},
          "id1": {_sig: "sig2"},
        },
        _hash: "hash",
        _type: "hash",
      };

      page = CopyPage(original_page);
      EntryDel(page, "id0");
    }
  end
end
