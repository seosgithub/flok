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
  //A FlokController will automatically be bound
  var src = "http://upload.wikimedia.org/wikipedia/commons/d/d9/Test.png"
  if_controller_init(3, 4, "my_test_controller2", {foo: src});

  //Attach that controller
  if_attach_view(4, 0);

  //Check img
  var $img = $("#root img");
  var _src = $img.attr("src");
  assert.equal(_src, src, "src is supposed to be a URL: " + src + ", but instead got: " + _src);
});

QUnit.test("When a button is clicked with the data-emit tag, it will signal the controller", function(assert) {
  $("body").html("                                            \
    <div id='prototypes'>                                     \
      <div class='view' data-name='my_test_view'>            \
      <button id='trigger_button_clicked' data-emit='button_clicked'>Click Me</button> \
      </div>                                                  \
    </div>                                                    \
    <div id='root'>                                           \
    </div>                                                    \
  ")      

  //Controller that will set the variable foo to button clicked when the action 'button_clicked' is received
  var TestController = function() {
    this.base = FlokController; this.base(); var self = this;

    self.init = function() {
      //You have access to 'context' in here
    }

    self.action = function(from, to) {
    }

    self.event = function(name, info) {
      if (name === "button_clicked") {
        foo = "button_clicked";
      }
    }
  }

  //Register the controller
  regController("__test__", TestController);

  //Create an instance of our prototype
  if_init_view("my_test_view", {}, 4, ["main"]);

  //Bind the controller to our view and set the bp to 3
  if_controller_init(3, 4, "__test__", {});

  //Attach that view's controller to the root spot
  if_attach_view(4, 0);

  var $button = $("#root #trigger_button_clicked");
  $button.trigger("click");
  assert.equal(foo, "button_clicked", "Button was supposed to trigger a clicked event, but it did not");
});
