//The prototype controller
//////////////////////////////////////////////////////////////////////////////////////
FlokController = function() {
  //Called internally when the controller is initialized from a if_controller_init
  this.__initialize__ = function(bp, $sel, info) {
    this.bp = bp;
    this.info = info;
    this.$_sel = $sel;
  }

  this.$sel = function(str) {
    return $(str, this.$_sel).not(".spot *")
  }

  //User defined init function
  this.init = function() {
  }

  //Send a message
  this.send = function(name, info) {
    int_dispatch([3, "int_event", this.bp, name, info]);
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
  var keys = Object.keys(cinstances).map(function(item) {
    return parseInt(item, 10);
  });

  int_dispatch([1, "spec", keys]);
}

//Spec init controller
function if_spec_controller_init() {
  var TestController = function() {
    this.base = FlokController; this.base();

    this.action = function(from, to) {
      this.send("action_rcv", {from: from, to:to});
    }

    this.event = function(name, info) {
      this.send("custom_rcv", {name:name, info:info})
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

//Controller destruction is in ui.js under 'delete cinstances'
