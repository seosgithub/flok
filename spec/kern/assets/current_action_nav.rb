controller :my_controller do
  macro :nav do
    #This one should only go to home if we are
    #not on home already
    on "home_clicked", %{
      if (current_action !== "home") {
        Goto("home");
      }
    }

    #This one should always go home, even if we are
    #on home already
    on "home_reload_clicked", %{
      Goto("home");
    }

    on "about_clicked", %{
      if (current_action !== "about") {
        Goto("about");
      }
    }
  end

  action :home do
    nav
  end

  action :about do
    nav
  end
end
