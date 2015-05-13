//The prototype controller
//////////////////////////////////////////////////////////////////////////////////////
FlokController = function() {
  //Called internally when the controller is initialized from a if_controller_init
  this.__initialize__ = function(bp, $sel, context) {
    this.bp = bp;
    this.context = context;
    this.$_sel = $sel;
  }

  this.$sel = function(str) {
    //Oh boy this sucked to come up with...
    //Do not allow selection of descendents of a spot
    //Read it as "Select all sub elements matching query
    //as long as they are not a descedente of a spot of this
    //current selector (spots are in spots, and we might be 
    //globally inside a spot, but the selector should ignore
    //that and look for local spots inside the current selector)
    return $(str, this.$_sel).not($(".spot *", this.$_sel));
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
    this.base = FlokController; this.base(); self = this;

    self.action = function(from, to) {
      self.send("action_rcv", {from: from, to:to});
    }

    self.event = function(name, info) {
      self.send("custom_rcv", {name:name, info:info})
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
