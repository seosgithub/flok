service("timer") do
  on_init %{
    //Entries in the timer event table are stored as an array of arrays, each array
    //contains [N, bp, event_name]

    var timer_evt = [];
    //Call an event N times per second
    function reg_timer_ev(n, bp, ename) {
      timer_evt.push([n, bp, ename]);
    }

    //Timer position
    var ttick = 0;
    function int_timer() {
      ttick += 1;

      for (var i = 0; i < timer_evt.length; ++i) {
        if (ttick % timer_evt[i][0] == 0) {
          var bp = timer_evt[i][1];
          var ename = timer_evt[i][2];
          int_event(bp, ename, {});
        }
      }
    }
  }

  on_request %{
    timer_evt.push([info.ticks, ep, ename]);
  }
end
