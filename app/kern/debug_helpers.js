<% if @debug %>
  function xinspect(o,i){
      if(typeof i=='undefined')i='';
      if(i.length>50)return '[MAX ITERATIONS]';
      var r=[];
      for(var p in o){
          var t=typeof o[p];
          r.push(i+'"'+p+'" ('+t+') => '+(t=='object' ? 'object:'+xinspect(o[p],i+'  ') : o[p]+''));
      }
      return r.join(i+'\n');
  }

  //Assert that params[key] is a string value
  function assert_arg_is_str(params, key, fail_msg) {
    //Pass
    if (typeof params[key] === 'string' || params[key] instanceof String) { return }

    var msg = fail_msg + ": Argument with key '" + key + "' was ";

    //What type is it?
    if (params[key] === undefined) { 
      msg += "(type: undefined)"; 
    } else if (params[key] === null) { 
      msg += "(type: null)"; 
    } else {
      msg += "(type: " + typeof params[key] + "?, value: " + params[key] + ")"
    }

    msg += " --- params: " + xinspect(params);
    throw msg;
  }
<% end %>
