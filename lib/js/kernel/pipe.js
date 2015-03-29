Kernel.process = function(event) {
  var type = event.type;
  //All events need a type
  if (type === undefined) { throw "Kernel got an event that had no type!"; }

  if (Kernel.hasInit === false) {
    if (type === "init") {
      Kernel.handleInitEvent(event);
    } else {
      throw "Kernel got a first event that was not an init, it was " + type
    }
  } else {
    //Is this a special event?
    if (type === "tick") {
      Kernel.handleTickEvent(event);
    } else {
      Kernel.handleCustomEvent(type, event);
    }
  }

  //Return outbound event queue
  var queue = Kernel.outboundEventQueue;
  Kernel.outboundEventQueue = [];
  return queue;
}

Kernel.outboundEventQueue = [];
Kernel.sendEvent = function(event) {
  Kernel.outboundEventQueue.push(event);
}
