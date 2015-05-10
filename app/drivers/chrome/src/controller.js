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
    cinstances[bp] = new controller(bp, $sel);

    cinstances[bp].init(info);
  }
}

//Spec helpers
function if_spec_controller_list() {
  int_dispatch([1, "spec", Object.keys(cinstances).map(parseInt)]);
}

function if_spec_controller_init() {
  var TestController = function(bp, $sel) {
    //Setup your object
    this.init = function(info) {
    }

    //Action has changed
    this.action = function(from, to) {
    }
  }

  //Register the new controller
  $(document).ready(function() {
    regController("__test__", TestController);
  });
}
