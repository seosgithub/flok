function rtc_callback() {
  //Call timer interrupt
  int_dispatch([0, "int_rtc", Math.floor(new Date() / 1000)]);
}

function if_rtc_init(tps) {
  //Call timer 1 time per second
  setInterval(rtc_callback, 1000.0);
}
