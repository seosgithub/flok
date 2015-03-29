Rebar.process = function(event) {
  var type = event.type;
  //All events need a type
  if (type === undefined) { throw "Rebar got an event that had no type!"; }

  if (Rebar.hasInit === false) {
    if (type === "init") {
      Rebar.handleInitEvent(event);
    } else {
      throw "Rebar got a first event that was not an init, it was " + type
    }
  } else {
    //Is this a special event?
    if (type === "tick") {
      Rebar.handleTickEvent(event);
    } else {
      Rebar.handleCustomEvent(type, event);
    }
  }

  //Return outbound event queue
  var queue = Rebar.outboundEventQueue;
  Rebar.outboundEventQueue = [];
  return queue;
}

Rebar.outboundEventQueue = [];
Rebar.sendEvent = function(event) {
  Rebar.outboundEventQueue.push(event);
}
