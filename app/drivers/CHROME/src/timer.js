function timer_callback() {
  //Call timer interrupt
  int_dispatch([0, "int_timer"]);
}

function if_timer_init(tps) {
  //Call timer n times per second
  setInterval(timer_callback, 1.0/tps*1000.0);
}
