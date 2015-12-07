function int_embed_surface(sp) {
}

function find_view(bp, spider) {
  var ctable = tel_deref(bp);
  var embeds = ctable.embeds;

  var output = {};

  for (var x = 0; x < embeds.length; ++x) {
    for (var i = 0; i < embeds[x].length; ++i) {
      var _ctable = tel_deref(embeds[x][i]);
      var name = _ctable.cte.name;

      if (spider[_ctable.cte.name]) {
        output[spider[_ctable.cte.name].__leaf__] = embeds[x][i];
      } else if (spider["."]) {
        output[spider["."].__leaf__] = embeds[x][i];
      }

    }
  }
  return output;
}

//Used by the delayed free views typically for the GOTO hook specifically
var views_to_free = {};
