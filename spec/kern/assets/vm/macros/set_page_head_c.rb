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
      SetPageHead(page, "test");
    }
  end
end
