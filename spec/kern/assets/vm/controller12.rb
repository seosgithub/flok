controller :my_controller do
  services :vm

  on_entry %{
      read_res_params = [];
  }

  action :my_action do
    on_entry %{
    }

    on "write_first", %{
      var page = vm_create_page("test")
      info_write = {ns: "spec", page: page}
      Request("vm", "write", info_write);
      context.page = page;
    }

    on "watch_first", %{
      var info_watch = {ns: "spec", id: "test"}
      Request("vm", "watch", info_watch);
    }

    on "modify_first", %{
      var page = vm_copy_page(context.page);
      page.entries.push({
        _sig: "test",
        _id: "test",
        value: "test"
      });
      var info_write = {ns: "spec", page: page};
      Request("vm", "write", info_write);
    }


    on "read_res", %{
      read_res_params.push(params);
    }
  end
end
