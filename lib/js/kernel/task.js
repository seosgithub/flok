//Global task list
Kernel.tasks = [];

Kernel.Task = function(name) {
  this.name = name;
  Kernel.tasks.push(this);

  this.sendEvent = function(type, info) {
    info.type = type;
    Kernel.sendEvent(info);
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
