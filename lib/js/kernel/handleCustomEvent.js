//Forward all custom events to all tasks
Kernel.handleCustomEvent = function(type, event) {
  var len = Kernel.tasks.length;
  for (var i = 0; i < len; ++i) {
    var task = Kernel.tasks[i]
    task.handle(type, event)
  }
}
