//Forward all custom events to all tasks
Rebar.handleCustomEvent = function(type, event) {
  var len = Rebar.tasks.length;
  for (var i = 0; i < len; ++i) {
    var task = Rebar.tasks[i]
    task.handle(type, event)
  }
}
