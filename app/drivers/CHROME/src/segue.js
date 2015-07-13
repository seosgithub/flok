//Do some segue with two views (tp1 and tp2)
function if_segue_do(name, tp1, tp2) {
  console.log("if segue do");
  if (if_segue_name_to_call[name] === undefined) {
    throw "You have not registered a segue with the name: "+name;
  }

  $sel1 = if_ui_tp_to_selector[tp1];
  $sel2 = if_ui_tp_to_selector[tp2];
  if_segue_name_to_call[name]($sel1, $sel2);
}

//Your segue function should accept two views $sel1, $sel2
if_segue_name_to_call = {
}
function segue(name, call_this) {
  if_segue_name_to_call[name] = call_this;
}
