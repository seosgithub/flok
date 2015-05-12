//Create a new surface based on a prototype name and information.
//Store that view in our own pointer table that uses selectors
if_ui_tp_to_selector = {};

function if_init_view(name, info, tp_base, tp_targets) {
  //Get the prototype that matches
  var $proto = $("#prototypes").find(".view[data-name=\'"+name+"\']");
  if ($proto.length === 0) { throw "Couldn't find a surface prototype named: "+name; }

  //Get a UUID, move the surface to the 'body' element and hidden
  var uuid = UUID();
  $proto.attr("data-uuid", uuid);
  $proto.attr("data-tp", tp_base);
  $proto.hide();
  $("body").append($proto[0].outerHTML);
  $proto.removeAttr("data-uuid");
  $proto.removeAttr("data-tp");

  var $sel = $("[data-uuid='" + uuid + "']");
  $proto.show();

  //Put the base view inside
  var tp_idx = tp_base; //Start with the base pointer
  tp_targets.forEach(function(target) {
    //The actual view, or lookup the spot and store it's selector
    if (target == "main") {
      if_ui_tp_to_selector[tp_idx] = $sel;
    } else {
      var $spot_sel = $sel.find('.spot[data-name='+target+']');
      if ($spot_sel.length == 0) { throw "Couldn't find a spot with the name: "+target}

      if_ui_tp_to_selector[tp_idx] = $spot_sel;
      $spot_sel.attr("data-tp", tp_idx);
    }

    tp_idx += 1;
  });

  //Our surface pointers are selectors
  return $sel
}

function if_attach_view(vp, p) {
  var $target = null;
  if (p == 0) {
    $target = $("#root")
  } else {
    //Lookup view selector
    $target = if_ui_tp_to_selector[p];
  }

  //Inject the view into p
  var $view = if_ui_tp_to_selector[vp];

  $view.show();
  $view.appendTo($target);
}

function if_free_view(vp) {
  var $view = if_ui_tp_to_selector[vp];

  //Find any child view vps
  var cvps = $.makeArray($view.find(".view").map(function() {
    return parseInt($(this).attr("data-tp"), 10);
  }));

  //Destroy all
  for (var i = 0; i < cvps.length; ++i) {
    delete if_ui_tp_to_selector[cvps[i]];

    //controllers are always at bp, bp+1 is always  a view
    delete cinstances[cvps[i]-1];
  }

  $view.remove();
  delete if_ui_tp_to_selector[vp];

  //controllers are always at bp, bp+1 is always  a view
  delete cinstances[vp-1];
}

//Spec related////////////////////////////////////////////////
function if_ui_spec_init() {
  //Set the body HTML
  var body_html = "                                  \
    <div id='root'></div>                            \
                                                     \
    <div id='prototypes' style='display: none'>      \
      <div class='view' data-name='spec_blank'>      \
      </div>                                         \
      <div class='view' data-name='spec_one_spot'>   \
        <div class='spot' data-name='content'></div> \
      </div>                                         \
      <div class='view' data-name='spec_two_spot'>   \
        <div class='spot' data-name='a'></div>       \
        <div class='spot' data-name='b'></div>       \
      </div>                                         \
    </div>                                           \
                                                     \
  "
  $("body").html(body_html);
}

function if_ui_spec_views_at_spot(p) {
  //Find target////////////////////////
  var $target = null;

  //Root view
  if (p == 0) {
    $target = $("#root")
  } else {
    //Lookup telepointer for selector
    $target = if_ui_tp_to_selector[p]
  }
  ////////////////////////////////////

  //Pull the telepointers from each child node
  var res = $target.children().map(function() {
    return parseInt($(this).attr("data-tp"));
  });
  res = $.makeArray(res);

  //Dispatch info
  var out = [res.length, "spec"];
  out = out.concat(res);
  int_dispatch(out);
}

function if_ui_spec_view_is_visible(p) {
  //Find target////////////////////////
  var $target = null;

  //Root view
  if (p == 0) {
    $target = $("#root")
  } else {
    //Lookup telepointer for selector
    $target = if_ui_tp_to_selector[p]
  }
  ////////////////////////////////////

  int_dispatch([1, "spec", !($target.css("display") === "none")]);
}

function if_ui_spec_view_exists(p) {
  //Find target////////////////////////
  var $target = null;

  //Root view
  if (p == 0) {
    $target = $("#root");
  } else {
    //Lookup telepointer for selector
    $target = if_ui_tp_to_selector[p];
  }
  ////////////////////////////////////

  var res = (if_ui_tp_to_selector[p] !== undefined);
  int_dispatch([1, "spec", res]);
}
/////////////////////////////////////////////////////////////
