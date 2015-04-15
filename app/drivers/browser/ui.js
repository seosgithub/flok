drivers = window.drivers || {}
drivers.ui = {}

//Surfaces added by the user, each has a 'key'
drivers.ui.surfaceIndex = 0

//Compile the named selectors
///////////////////////////////////////////////////////////////////////////////////////
$(document).ready(function() {
  //Surface prototypes hold the prototype views
  drivers.ui.$surfacePrototypes = $("#surface-prototypes")

  //The root view resides with the key 0, all other selectors are built using surface_index#view_name
  drivers.ui.$viewHashToSelector = {}
  drivers.ui.slaveHashesOfSurfaceWithIndex = {} //Delete all these hashes when a request for deletion compes in
  drivers.ui.$viewHashToSelector[drivers.ui.getViewHash(drivers.ui.surfaceIndex++)] = $('#root-surface')
  drivers.ui.parentHashOfSurface = {}
})

//When looking up a view, this hash is used
drivers.ui.getViewHash = function(surfaceIndex, viewName) {
  if (viewName === undefined || viewName === null) { return surfaceIndex }
  return surfaceIndex + '#' + viewName
}

//Retrieve a view by surfaceIndex and optionally, the specific view
//drivers.ui.$getView(surfaceIndex) //This will retrieve the 'root' view which is the surface itself
//drivers.ui.$getView(surfaceIndex, 'header') //This will give you the 'data-view-name=header' inside a surface
drivers.ui.$getView = function(surfaceIndex, viewName) {
  //Else, retrieve it and fail if it dosen't exist
  var selector = drivers.ui.$viewHashToSelector[drivers.ui.getViewHash(surfaceIndex, viewName)]
  if (selector === undefined) {
    console.log('Couldn\'t find view located on a surface with index: '+surfaceIndex+' and name of: '+name)
    return undefined
  }

  return selector
}
///////////////////////////////////////////////////////////////////////////////////////

//Get the selector for a surface prototype by name
///////////////////////////////////////////////////////////////////////////////////////
drivers.ui.$surfaceNameToPrototype = {}
drivers.ui.$getSurfacePrototype = function(name) {
  if (drivers.ui.$surfaceNameToPrototype[name] === undefined) {
    var prototypes = drivers.ui.$surfacePrototypes;
    var matchingPrototype = prototypes.find("[data-surface-name=\'"+name+"\']");
    if (matchingPrototype.length === 0) { console.log("Could not find surface prototype for name: " + name); }
    drivers.ui.$surfaceNameToPrototype[name] = matchingPrototype
  }

  return drivers.ui.$surfaceNameToPrototype[name]
}
///////////////////////////////////////////////////////////////////////////////////////

//Create a surface 
drivers.ui.createSurface = function(name, surfaceIndex, viewName, info) {
  //Find relavent prototype
  var $surfacePrototype = drivers.ui.$getSurfacePrototype(name)

  //Add the uuid to the prototype
  var index = drivers.ui.surfaceIndex++

  //Make sure the parent surface knows about the child
  $surfacePrototype.attr("data-surface-index", index)
  drivers.ui.slaveHashesOfSurfaceWithIndex[drivers.ui.getViewHash(surfaceIndex)] = drivers.ui.slaveHashesOfSurfaceWithIndex[drivers.ui.getViewHash(surfaceIndex)] || [];
  drivers.ui.slaveHashesOfSurfaceWithIndex[drivers.ui.getViewHash(surfaceIndex)].push(drivers.ui.getViewHash(index));
  drivers.ui.parentHashOfSurface[index] = surfaceIndex;

  //Grab the prototype HTML and remove the index
  var html = $surfacePrototype[0].outerHTML
  $surfacePrototype.removeAttr("data-surface-index") //Lookup will be comprimised if we don't get rid now!

  //Now add the surface as a 'real' surface to the specified view selector
  $view = drivers.ui.$getView(surfaceIndex, viewName)
  $view.append(html);

  //Get a selector to this newly created surface
  $surface = $view.find("[data-surface-index=\'"+index+"\']");

  //Add the surface itself as a view.  This is getView without using a viewName
  drivers.ui.$viewHashToSelector[drivers.ui.getViewHash(index)] = $surface;

  //Find any views that need to be quantified (optional subviews)
  $surface.find("[data-view-name]").each(function() {
    //Get the view name
    var name = $(this).attr("data-view-name")

    //Place it in the correct place
    drivers.ui.$viewHashToSelector[drivers.ui.getViewHash(index, name)] = $(this)
  });
}

drivers.ui.destroySurface = function(surfaceIndex) {
  //Get all the child hashes
  var childHashes = drivers.ui.slaveHashesOfSurfaceWithIndex[drivers.ui.getViewHash(surfaceIndex)] || [];
  for (var i = 0; i < childHashes.length; ++i) {
    drivers.ui.destroySurface(childHashes[i]);
  }

  //Get hash
  var hash = drivers.ui.getViewHash(surfaceIndex);

  //Remove surface from HTML
  drivers.ui.$getView(surfaceIndex).remove();

  //Remove surface from dictionary
  delete drivers.ui.$viewHashToSelector[hash];


  var slaveArrayForParent = drivers.ui.slaveHashesOfSurfaceWithIndex[drivers.ui.parentHashOfSurface[surfaceIndex]];
  var index = slaveArrayForParent.indexOf(surfaceIndex);
  slaveArrayForParent.splice(index, 1)

  drivers.ui.slaveHashesOfSurfaceWithIndex[drivers.ui.parentHashOfSurface[surfaceIndex]] = slaveArrayForParent;
}
