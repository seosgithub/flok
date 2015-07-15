controller :my_controller do
  spots "content"

  choose_action do
    on_entry %{
    }
  end

  action "index" do
    index_entered = true;
  end

  action "alt" do
    alt_entered = true;
  end
end
