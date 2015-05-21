//Testing the debug view (when if_init_view is called without an existing prototype)

QUnit.test("When if_init_view is called without a view, a view is forged", function(assert) {
  //var done = assert.async();

  $("body").append("<div id='prototypes'></div><div id='root'></div>")

  if_init_view("my_test_view", {}, 0, ["main", "content"]);

  //Should have 1 thing in the prototypes
  assert.equal($("#prototypes .view[data-name='my_test_view']").length, 1, "Matches");

  //It should have a spot named content
  assert.equal($("#prototypes .view[data-name='my_test_view'] .spot[data-name='content']").length, 1, "Matches");

  //Should not have a main spot though
  assert.equal($("#prototypes .view[data-name='my_test_view'] .spot[data-name='main']").length, 0, "Matches");
});
