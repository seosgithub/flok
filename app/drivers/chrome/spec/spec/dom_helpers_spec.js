//Testing the DOM binding like data-puts to make sure they work

QUnit.test("When the DOM bind data-puts is used with 'foo' in a controller that has a context containing foo, foo is put inside the HTML with the binding", function(assert) {
  $("body").html("                                            \
    <div id='prototypes'>                                     \
      <div class='view' data-name='my_test_view2'>            \
        <h1 id='check' data-puts='foo'></h1>                  \
      </div>                                                  \
    </div>                                                    \
    <div id='root'>                                           \
    </div>                                                    \
  ")      

  //Create a view
  if_init_view("my_test_view2", {}, 4, ["main"]);

  //Bind a controller to that view with a context
  //A DebugController will automatically be bound
  if_controller_init(3, 4, "my_test_controller2", {foo: "hello world"});

  //Attach that controller
  if_attach_view(4, 0);

  //Check h1
  var $h1 = $("#root h1");
  var html = $h1.html();
  assert.equal(html, "hello world", "html is equal to hello world, got: " + html);
});

QUnit.test("When the DOM bind data-puts is used with 'src foo' in a controller that has a context containing foo, foo is put inside the src tag with the binding", function(assert) {
  $("body").html("                                            \
    <div id='prototypes'>                                     \
      <div class='view' data-name='my_test_view2'>            \
        <img id='check' data-puts='src foo'></h1>                  \
      </div>                                                  \
    </div>                                                    \
    <div id='root'>                                           \
    </div>                                                    \
  ")      

  //Create a view
  if_init_view("my_test_view2", {}, 4, ["main"]);

  //Bind a controller to that view with a context
  //A DebugController will automatically be bound
  var src = "http://upload.wikimedia.org/wikipedia/commons/d/d9/Test.png"
  if_controller_init(3, 4, "my_test_controller2", {foo: src});

  //Attach that controller
  if_attach_view(4, 0);

  //Check img
  var $img = $("#root img");
  var _src = $img.attr("src");
  assert.equal(_src, src, "src is supposed to be a URL: " + src + ", but instead got: " + _src);
});
