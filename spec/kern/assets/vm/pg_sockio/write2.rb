controller :my_controller do
  services :vm

  on_entry %{
    read_res_params = [];

    /////////////////////////////////////////////////////////////////////////
    //Create a page and commit it to the sockio cache (cheating)
    //This way we know a commit should be performed when a write goes through
    /////////////////////////////////////////////////////////////////////////
    var page = vm_create_page("test");
    page.entries.push(
      {"_id": "test", "_sig": "test", "val": "test"}
    );
    vm_reindex_page(page);
    vm_rehash_page(page);
    vm_cache["sockio"]["test"] = page;
    /////////////////////////////////////////////////////////////////////////
  }

  action :my_action do
    on_entry %{
      var page = vm_create_page("test");

      var info = {
        ns: "sockio",
        page: page,
      };

      Request("vm", "write", info);
    }

    on "read_res", %{
      read_res_params.push(JSON.parse(JSON.stringify(params)));
    }
  end
end
