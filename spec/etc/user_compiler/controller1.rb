controller :my_controller do
  view :test_view

  action :my_action do
    on_entry {%{
      function 
    }}
  end
end
