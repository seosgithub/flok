controller :my_controller do
  services :vm

  action :foo do
    on_entry %{
      var page = vm_create_page("test");
      var info = {
        ns: "user",
        page: page,
        id: page._id,
      }
      Request("vm", "write", info);
    }

    on "next_clicked", %{
      Goto("bar");
    }
  end

  action :bar do
    on_entry %{
      var page = vm_create_page("test");
      var info = {
        ns: "user",
        id: "test",
        page: page,
      }
      Request("vm", "watch", info);
      Request("vm", "invalidate", info);
      Request("vm", "write", info);
    }

    on "read_res", %{
      read_res_params = params;
    }

    on "invalidated", %{
      invalidate_res = params;
    }
  end
end
