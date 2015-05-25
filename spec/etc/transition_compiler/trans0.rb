transition :test do
  controller :my_controller
  from :index
  to :about

  path :home, "./content.0"
  path :home, "./content.1"
end

transition :test2 do
  controller :my_controller
  from :index
  to :about2

  path :home, "./content.0"
  path :home, "./content.1"
end
