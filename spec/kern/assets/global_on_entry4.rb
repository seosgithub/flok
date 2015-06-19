controller :my_controller do
  on_entry %{
    context.secret = "foo";
    context.base = __base__;
  }

  action :index do
    on_entry %{
      Send("context", context);
    }
  end
end
