controller :controller do
  action :index do
    on_entry %{
      original_page = {
        _head: "head",
        _next: "next",
        _id: "id",
        entries: [
          {_id: "id", _sig: "sig"},
          {_id: "id2", _sig: "sig2"},
          {_id: "id3", _sig: "sig3"},
        ],
        _hash: "hash",
      };

      page = CopyPage(original_page);
      EntryMutable(page, 0);
      EntryMutable(page, 2);

      page.entries[0].hello = "world";
      page.entries[2].hello = "world";

      //This is a violation of the vm, it will set the original but not copied
      //This is because the page.entries[1] actually refers to the original_page.entries[1]
      //the array of original_page.entries belongs to original_page, but the entries inside it
      //are references. When you call entrymutable, you are making a copy and replacing that
      //entry in the array so that page.entries[0] is actually owned by page and is no longer apart
      //of original_page
      page.entries[1].foo = "bar";
    }
  end
end

