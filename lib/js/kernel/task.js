//Global task list
Rebar.tasks = [];

Rebar.Task = function(name) {
  this.name = name;
  Rebar.tasks.push(this);

  this.sendEvent = function(type, info) {
    info.type = type;
    Rebar.sendEvent(info);
  }

  var handlers = [];
  this.on = function(name, callback) {
    handlers[name] = callback;
  }

  this.handle = function(type, event) {
    handler = handlers[type];
    if (handler != undefined) {
      handler(event)
    }
  }
}
