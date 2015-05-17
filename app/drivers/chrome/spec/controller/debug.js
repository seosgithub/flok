//Testing the controller to make sure it gets properly attached to debug views

$(document).ready(function() {
  QUnit.test("when if_controller_init is called with a view that has the debug flag on, it uses the DebugController", function(assert) {
    //Setup prototypes html
    $("body").append("<div id='prototypes'></div>")
    if_init_view("my_test_view", {}, 1, ["main", "content"]);

    //Create a controller that belongs to a debug view (it has data-debug='1')
    if_controller_init(0, 1, "my_test_controller", {});

    //Uses DebugController
    assert.equal(cinstances[0].constructor, DebugController, "")

    //Has the correct name
    assert.equal(cinstances[0].name, "my_test_controller", "")
  });
});
