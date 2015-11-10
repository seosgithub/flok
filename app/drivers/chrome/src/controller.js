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

  //Called after init automatically to apply special helper bindings
  this.apply_helpers = function() {
    var self = this;

    //Emit an event
    this.$sel("[data-emit]").on("click", function() {
      var name = $(this).attr("data-emit");
      self.send(name, {});
    });

    //Set the HTML
    this.$sel("[data-puts]").each(function() {
      //Retreive the args, seperated by spaces
      var args = $(this).attr("data-puts");
      args = args.split(" ");

      //  2 args => set the attribute named args[0] to the value of context[args[1]]
      if (args.length == 1) {
        $(this).html(self.context[args[0]]);
      } else if (args.length == 2) {
        $(this).attr(args[0], self.context[args[1]]);
      }
    });
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

<% if @debug %>
//Debug controller
//////////////////////////////////////////////////////////////////////////////////////
//Accepts name because we need to keep track of the controller's name
var DebugController = function(name) {
  this.base = FlokController; this.base(); var self = this;
  this.name = name;

  this.init = function() {
    self.$sel("#controller_name").html(name);
    self.$sel("#context").html(JSON.stringify(self.context));
  }

  this.action = function(from, to) {
    self.$sel("#action_name").html(to);
  }

  this.event = function(name, info) {
    self.$sel("#last_event .name").html(name);
    self.$sel("#last_event .info").html(JSON.stringify(info));
  }
}
//////////////////////////////////////////////////////////////////////////////////////
<% end %>

//Controller works with the ui module and segue module
reg_controllers = {};

//Should be called in your document ready before initialization of flok
function regController(name, constructor) {
  reg_controllers[name] = constructor;
}

//Keep track of active controllers
var cinstances = {};

function if_controller_init(bp, rvp, name, info) {
  <% if @debug %>
    if (if_ui_tp_to_selector[rvp].attr("data-debug") === '1') {
      reg_controllers[name] = DebugController;
    } else if (reg_controllers[name] === undefined) {
      reg_controllers[name] = FlokController;
    }
  <% end %>

  if (reg_controllers[name] != undefined) {
    //Grab controller
    var controller = reg_controllers[name];

    //Get selector
    var $sel = if_ui_tp_to_selector[rvp];

    //If it is a debug view, pass some info along to it
    <% if @debug %>
      if (controller == DebugController) {
        var c = new controller(name)
      } else {
        var c = new controller();
      }
    <% else %>
      var c = new controller();
    <% end %>

    c.__initialize__(bp, $sel, info);
    cinstances[bp] = c;

    //Initialize
    cinstances[bp].init();
    cinstances[bp].apply_helpers(); //emit, puts
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

  var TestControllerContext = function() {
    this.base = FlokController; this.base(); self = this;

    this.init = function() {
      self.send("context", self.context)
    }

    self.action = function(from, to) {
      self.send("action_rcv", {from: from, to:to});
    }

    self.event = function(name, info) {
      self.send("custom_rcv", {name:name, info:info})
    }
  }


  //Register the new controller
  $(document).ready(function() {
    regController("spec_blank", TestController);
    regController("spec_one_spot", TestController);
    regController("spec_blank_sends_context", TestControllerContext);
  });
}

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//Controller events are handled in if_event.js
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

//Controller destruction is in ui.js under 'delete cinstances'
