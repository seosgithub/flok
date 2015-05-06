controller :my_controller do
  view :test_view

  action :my_action do
    on_entry do
      "var x = 4;"
    end

    on "hello" do
      "var x = 3;"
    end
  end
end
