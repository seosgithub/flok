controller :my_controller do
  services :vm

  on_entry %{
    entry_move_params = [];
    entry_modify_params = [];
    entry_del_params = [];
    entry_ins_params = [];
  }

  action :my_action do
    on_entry %{
      var info = {ns: "dummy", id: "default"};
      Request("vm", "watch", info);
    }

    on "entry_move", %{
      entry_move_called = true;
      entry_move_params.push(params);
    }

    on "entry_modify", %{
      entry_modify_called = true;
      entry_modify_params.push(params);
    }

    on "entry_del", %{
      entry_del_called = true;
      entry_del_params.push(params);
    }

    on "entry_ins", %{
      entry_ins_called = true;
      entry_ins_params.push(params);
    }
  end
end
