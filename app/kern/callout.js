callout_tick = 0;
callout_queue = {};

function callout_wakeup() {
  callout_tick += 1;

  //Get an array of things that should fire now
  var arr = callout_queue[callout_tick];
  if (arr === undefined) {
    return;
  }
  delete callout_queue[callout_tick];

  for (var i = 0; i < arr.length; ++i) {
    var e = arr[i];

    //Send event
    var ep_ok = int_event(e.ep, e.ename, {});

    //Reschedule interval if the ep still exists
    if (e.interval && ep_ok) {
      reg_interval(e.ep, e.ename, e.ticks);
    }
  }
}

function reg_timeout(ep, ename, ticks) {
  //Create an array if there isn't already one
  if (callout_queue[ticks+callout_tick] === undefined) {
    callout_queue[ticks+callout_tick] = [];
  }

  //Insert an item
  callout_queue[ticks+callout_tick].push({
    ep: ep,
    ename: ename,
    ticks: ticks,
    interval: false
  });
}

function reg_interval(ep, ename, ticks) {
  //Create an array if there isn't already one
  if (callout_queue[ticks+callout_tick] === undefined) {
    callout_queue[ticks+callout_tick] = [];
  }

  //Insert an item
  callout_queue[ticks+callout_tick].push({
    ep: ep,
    ename: ename,
    ticks: ticks,
    interval: true 
  });
}
