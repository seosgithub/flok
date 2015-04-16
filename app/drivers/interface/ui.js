//Handles displaying UI
//Key conceptsr
// 1) Surface is like a 'View Controller', a surface contains named views.
// 2) Creating a surface will never show anything. You must embed it.
// 3) Embedding a surface should only trigger an animation segue if animated is false.
// 4) 'sp' stands for 'surface pointer'.  This is an opaque type that is platform dependent.  
//    For websites it could be selectors. For iOS, it could be a UIView or UIViewController

//Surface structure
//{
//  parent: sp                 The surface that embedded this surface
//  childs: [sp, sp, sp, ...]  An array of surfaces that this embeds. N(childs) =< N(namedViews)
//}

//Create a new surface based on a prototype name and information. Should return a surface pointer
drivers.ui.createSurface = function(protoName, info) {
  return sp;
}

//Delete a surface which removes it from the UI
drivers.ui.deleteSurface = function(sp) {
}

//Embed a surface into another surface in the view with the correct name
//source_sp - The surface we are embedding
//dest_sp - The surface we are embedding into
//viewName - The name of the view in the destination surface
//animated - If true, a segue is allowed to take place
//animationDidComplete - Call this funtction if animated is true when you are done animating.
drivers.ui.embedSurface = function(source_sp, dest_sp, viewName, animated, animationDidComplete) {
}
