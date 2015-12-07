//GOTO hook generator expects this callback to be received usually for completion
function hook_goto_completion_cb(ep, ename, info) {
  var views_to_free_id = ep;
  var our_views_to_free = views_to_free[ep];

  delete views_to_free[ep];
  dereg_evt(ep);

  for (var key in our_views_to_free) {
    var bp = our_views_to_free[key];
    main_q.push([1, "if_free_view", bp]);
  }
}
