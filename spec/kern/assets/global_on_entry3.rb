controller :my_controller do
  on_entry %{
    global_on_entry_called_count += 1;
    Send("test", {});
  }

  action :index do
    on "next", %{
      Goto("test")
    }
  end

  action :test do
    on_entry %{
    }
  end
end
