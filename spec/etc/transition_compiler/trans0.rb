transition :my_controller_tab_bar do
  controller :my_controller
  from :blah
  to :blah2

  path :tab_bar, './content.1'
  path :home, './content.0'
end
