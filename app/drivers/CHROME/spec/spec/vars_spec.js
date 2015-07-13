//Tests various control variables, like context

QUnit.test("Controller does receive context on explicit init", function(assert) {
  var done = assert.async();

  //Create a test controller
  var TestController = function() {
    this.base = FlokController; this.base(); self = this;

    self.init = function() {
      assert.equal(this.context.hello, "world", "Matches");
      done();
    }
  }

  //Insert some HTML
  $("body").html("              \
    <div id='root'>             \
      <div id='test'></div>     \
    </div>                      \
  ");

  //Call the controllers init with a forged selector
  $sel = $("#test");
  var c = new TestController();
  c.__initialize__(0, $sel, {hello: 'world'});
  c.init();
});
