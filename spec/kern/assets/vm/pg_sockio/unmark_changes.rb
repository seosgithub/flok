controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
    }

    on "create_page", %{
      var page = vm_create_page("test");
      var info = {ns: "sockio", page: page};
      Request("vm", "write", info);

      var info2 = {ns: "sockio", id: "test"};
      Request("vm", "watch", info2);
    }

    on "modify_page", %{
      //Modify the page
      var new_page = vm_copy_page(read_page);

      new_page.entries.push({
        _id: gen_id(),
        _sig: gen_id(),
        value: "foo"
      });
      var info = {ns: "sockio", page: new_page}
      Request("vm", "write", info);
    }

    on "read_res", %{
      read_page = params;
    }
  end
end
