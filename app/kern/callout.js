//Each item in the callout queue is a hash that
//hash a 'next' field. The next field points to 
//the next entry. The first entry in each slot
//of the callout is either undefined or a hash containing
//only a next key. The first entry can be in one of 3 states:
//(1) Undefined, (2) A hash with an entry in next, (3) A hash
//with no entry in next.  The 'tick' is the actual total
//time that has elapsed, the 'head' is the tick with a modulus of 200
//to rotate in the callout, and the queue is held in 'queue'.
callout_tick = 0;
callout_head = 0;
callout_queue = {
}

function callout_wakeup() {
  //Increment tick (total) and head (relative)
  callout_head += 1;
  callout_head = callout_head % 200;
  callout_tick += 1;

  //The last item while going through loop, first time
  //through the loop it defaults to the first entry
  //of the callout queue
  prev_item = callout_queue[callout_head];

  //If nothing was ever scheduled in this slot,
  //prev_item (the head pointer) will be undefined. If something
  //was scheduled but is now removed, this slot will have nothing
  //but a next pointer inside of it.
  if (prev_item === undefined || prev_item.next === undefined) {
    return;
  }

  //While there are still things to find
  while (1) {
    //Get the next item
    var item = prev_item.next;

    //There is nothing next
    if (item === undefined) {
      break;
    }

    //This item needs to run *now*
    if (item.fire_tick <= callout_tick) {
      //Remove from queue, prev_item.next used to be just 'item'
      prev_item.next = item.next;

      //Send an event
      int_event(item.ep, item.ename, {});

      //If the item is repeated, then it should be re-adedd
      if (item.repeat) {
        reg_timer(item.ep, item.ename, item.ticks);
      }

      //Move-along, do not re-assign prev_item because
      //it is still the same
      continue;
    }

    //I am now the new item
    prev_item = item;
  }
}

function reg_timer(ep, ename, ticks) {
  var aticks = Math.abs(ticks);
  var item = {
        ep: ep,
        ename: ename,
        fire_tick: aticks+callout_tick,
        repeat: (ticks < 0),
        ticks: ticks,
  }
  if (callout_queue[aticks%200] === undefined) {
    callout_queue[aticks%200] = {
      next: item
    }
  } else {
    item.next = callout_queue[aticks%200].next;
    callout_queue[aticks%200] = {
      next: item
    }
  }
}
