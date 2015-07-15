controller :my_controller do
  spots "content"

  on_entry %{
    on_entry_call_order = ["global_on_entry"];
  }

  action "index" do
    on_entry %{
      on_entry_call_order.push("index_on_entry");
    }
  end

  action "alt" do
  end
end
