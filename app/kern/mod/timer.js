//SEND("cpu", "if_timer_init", 4);

function int_timer() {
  callout_wakeup();
}
