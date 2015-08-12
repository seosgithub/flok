controller :my_controller do
  services :vm

  action :my_action do
    on_entry %{
      //Setup watch
      var watch_info0 = { ns: "sockio", id: "test0", };
      var watch_info1 = { ns: "sockio", id: "test1", };

      Request("vm", "watch", watch_info0);
      Request("vm", "watch", watch_info1);
    }

    on "write_test1", %{
      //Write test1
      var test1 = vm_create_page("test1");
      var write_info1 = { ns: "sockio", page: test1};
      Request("vm", "write", write_info1);
    }

    on "read_res", %{
      read_res_params = params;
    }

    #Unwatch test1 page
    on "unwatch_test1", %{
      var unwatch_info1 = { ns: "sockio", id: "test1", };
      Request("vm", "unwatch", unwatch_info1);
    }
  end
end
