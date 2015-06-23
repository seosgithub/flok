controller :my_controller do
  services "vm"

  on_entry %{
    context.secret = "foo";
    context.base = __base__;

    var page = NewPage("array", "test");
    var info = {
      page: page,
      ns: "spec0",
      id: "test"
    }
    Request("vm", "write", info);

    Request("vm", "watch", info);
  }

  action :index do
    on_entry %{
      Send("context", context);
    }

    on "read_res", %{
      read_res_called = true;
    }
  end
end
