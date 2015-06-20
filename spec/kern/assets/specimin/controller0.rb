controller :workout_window_exercise do
  spots "verb"

  on_entry %{
    context.ep = context.ep;
    context.ui_title = context.ui_title;
    context.image_url = context.image_url;
  }

  action :verb do
    on_entry %{
      var ctx = {
        parent: context,
      }

      if (context.ep.verb_type == "seconds") {
        Embed("exercise_verb_secs", "verb", ctx);
      }
    }

    on "verb_secs_completed", %{
      Goto("presay");
    }
  end

  action :presay do
    on_entry %{

      var ctx = {
        parent: context,
      }
      Embed("workout_window_exercise_presay", "verb", ctx);
    }

    on "start_clicked", %{
      Goto("countdown");
    }
  end

  action :countdown do
    on_entry %{
      Embed("workout_window_exercise_countdown", "verb", {});
    }

    on "countdown_finished", %{
      Goto("verb");
    }
  end

end

#Verb Seconds
####################################################################################################
controller :exercise_verb_secs do
  action :index do
    on_entry %{
      context.seconds = context.parent.ep.seconds;
    }

    every 1.seconds, %{
      if (context.seconds == 0) {
      debugger;
        Raise("verb_secs_completed", {});
        return;
      }

      context.seconds -= 1;

      Send("seconds", context.seconds.toString());
    }
  end
end
####################################################################################################

