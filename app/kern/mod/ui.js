function int_embed_surface(sp) {
}

function find_view(bp, spider) {
  var res = {};
  _find_view(bp, spider, res);

  return res;
}

function _find_view(bp, spider, shared) {
  var leaf = spider["__leaf__"];
  if (leaf) {
    shared[leaf] = bp
  }

  var ctable = tel_deref(bp);
  var embeds = ctable.embeds;

  var output = {};

  for (var x = 0; x < embeds.length; ++x) {
    for (var i = 0; i < embeds[x].length; ++i) {
      //Pull info about the entry (subview)
      var entry_bp = embeds[x][i];
      var entry_cinfo = tel_deref(entry_bp); // The sub controller's info
      var entry_ctable = entry_cinfo.cte;    // The sub controller's ctable static
      var entry_name = entry_ctable.name;    // The sub controller's name

      //Direct match found
      var direct_match = spider[entry_name];
      var dot_match = spider["."];
      var plus_match = spider["+"];

      if (direct_match) {
        _find_view(entry_bp, direct_match, shared);
      } 
      
      if (dot_match) {
        _find_view(entry_bp, dot_match, shared);
      } 
      
      if (plus_match) {
        _find_view(entry_bp, plus_match, shared);
        var partial_plus = {
          "+": plus_match
        }
        _find_view(entry_bp, partial_plus, shared);
      }
    }
  }

  ////For all spots
  //for (var x = 0; x < embeds.length; ++x) {
    ////Search
    //for (var i = 0; i < embeds[x].length; ++i) {
      ////Lookup ctable for the embed
      //var _ctable = tel_deref(embeds[x][i]);

      ////Get it's name
      //var name = _ctable.cte.name;

      ////Does it match something in our spider?
      //if (spider[_ctable.cte.name]) {
        //output[spider[_ctable.cte.name].__leaf__] = embeds[x][i];
      //} else if (spider["."]) {
        //output[spider["."].__leaf__] = embeds[x][i];
      //}
    //}
  //}
  //return output;
}

//Used by the delayed free views typically for the GOTO hook specifically
var views_to_free = {};
