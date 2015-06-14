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

      //One page done the right away, another, the wrong way
      copied_page = CopyPage(original_page);
      not_copied_page = original_page;

      //The copied page is now modified and does
      //not contain _hash
      copied_page._next = "test"
    }
  end
end
