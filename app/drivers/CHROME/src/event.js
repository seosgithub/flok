function if_event(ep, name, info) {
  
  //Dispatch to controller if cinstances defines ep
  if (cinstances[ep] !== undefined) {
    if (name == "action") {
      cinstances[ep].action(info.from, info.to);
    } else {
      cinstances[ep].event(name, info);
    }
  }
}
