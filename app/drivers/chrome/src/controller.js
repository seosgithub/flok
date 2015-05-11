//The prototype controller
//////////////////////////////////////////////////////////////////////////////////////
FlokController = function() {
  //Called internally when the controller is initialized from a if_controller_init
  this.__initialize__ = function(bp, $sel, info) {
    this.bp = bp;
    this.$ = $sel.find;
    this.info = info;
  }

  //User defined init function
  this.init = function() {
  }

  //Send a message
  this.send = function(name, info) {
    int_dispatch([1, name, info]);
  }

  //Do nothing by default
  this.action = function(from, to) {
  }

  //Do nothing by default
  this.event = function(name, info) {
  }
}
//////////////////////////////////////////////////////////////////////////////////////

//Controller works with the ui module and segue module
reg_controllers = {};

//Should be called in your document ready before initialization of flok
function regController(name, constructor) {
  reg_controllers[name] = constructor;
}

//Keep track of active controllers
var cinstances = {};

function if_controller_init(bp, rvp, name, info) {
  if (reg_controllers[name] != undefined) {
    //Grab controller
    var controller = reg_controllers[name];

    //Get selector
    var $sel = if_ui_tp_to_selector[rvp];
    var c = new controller();
    c.__initialize__(bp, $sel, info);
    cinstances[bp] = c;

    cinstances[bp].init();
  }
}

//Spec helpers
//List all active controllers
function if_spec_controller_list() {
  int_dispatch([1, "spec", Object.keys(cinstances).map(parseInt)]);
}

//Spec init controller
function if_spec_controller_init() {
  var TestController = function() {
    this.base = FlokController; this.base();

    this.action = function(from, to) {
      this.send("spec", {from: from, to:to});
    }

    this.event = function(name, info) {
      this.send("spec", {name:name, info:info})
    }
  }

  //Register the new controller
  $(document).ready(function() {
    regController("__test__", TestController);
  });
}

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//Controller events are handled in if_event.js
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
