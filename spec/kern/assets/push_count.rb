#1. If we're in home, we should just raise back_clicked
#2. If we're in home, and push about, then we should pop
#3. If we're in about (start), then we should raise back_clicked
controller :my_controller do
  macro :nav do
    on "back_clicked", %{
      if (push_count === 0) {
        raised_back = true;
      } else {
        did_pop = true;
      }
    }
  end

  choose_action do
    on_entry %{
      if (context.starts_in_about) {
        Goto("about");
      } else {
        Goto("home");
      }
    }
  end

  action :home do
    on "about_clicked", %{
      Push("about");
    }
    nav
  end

  action :about do
    nav
  end
end
