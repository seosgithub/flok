controller :my_controller do
  spots "content"

  action :my_action do
    on_entry %{
      Embed("my_controller2", "content", {})
    }
  end
end

#This controller will receive test_event but should
#pass it up to 'my_controller'
controller :my_controller2 do

  action :my_action do
    on_entry %{
    }
  end
end
