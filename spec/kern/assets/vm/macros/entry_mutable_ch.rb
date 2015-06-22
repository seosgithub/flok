controller :controller do
  action :index do
    on_entry %{
      original_page = {
        _head: "head",
        _next: "next",
        _id: "id",
        _type: "hash",
        entries: {
          "id1": {_sig: "sig1"},
          "id2": {_sig: "sig2"},
        },
        _hash: "hash",
      };

      //Now we make a new copy
      page = CopyPage(original_page);
      var a = EntryMutable(page, "id1");
      var b = EntryMutable(page, "id2");

      a.hello = "world";
      b.hello = "world";

      //This is a violation of the vm, it will set the original but not copied
      //This is because the page.entries[1] actually refers to the original_page.entries[1]
      //the array of original_page.entries belongs to original_page, but the entries inside it
      //are references. When you call entrymutable, you are making a copy and replacing that
      //entry in the array so that page.entries[0] is actually owned by page and is no longer apart
      //of original_page
      original_page.entries["id1"].foo = "bar";
    }
  end
end

