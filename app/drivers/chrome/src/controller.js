//Controller works with the ui module and segue module

reg_controllers = {};

//Should be called in your document ready before initialization of flok
function regController(constructor, view_name) {
  reg_controllers[view_name] = constructor;
}
