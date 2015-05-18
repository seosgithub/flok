//Debug stub
function int_debug_eval(str) {
  var res = eval(str);
  var payload = {
    res: res
  }
  SEND("main", "if_event", -333, "eval_res", payload);
}

function debug_eval_spec() {
  return 'hello';
}
