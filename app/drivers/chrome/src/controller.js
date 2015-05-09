//Controller works with the ui module and segue module

reg_controllers = {};

//Should be called in your document ready before initialization of flok
function regController(name, constructor) {
  reg_controllers[name] = constructor;
}

function if_controller_init(bp, name, info) {
  if (reg_controllers[name] != undefined) {
    var controller = reg_controllers[name];
    var $sel = if_ui_tp_to_selector[bp];
    new controller($sel, bp, info);
  }
}
