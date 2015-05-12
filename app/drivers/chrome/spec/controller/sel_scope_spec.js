//Tests the $sel passed in a controller to make sure that it's scope
//is limited to the view the controller is bound to and not sub controllers
//or global controllers

$(document).ready(function() {
  QUnit.test("Controller selector cannot reach out of self", function(assert) {
    var done = assert.async();

    //Create a test controller
    var TestController = function() {
      this.base = FlokController; this.base(); self = this;

      self.init = function() {
        var matches = self.$sel("#root");
        assert.equal(matches.length, 0, "Matches are 0");
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
    c.__initialize__(0, $sel, {});
    c.init();
  });

  QUnit.test("Controller selector can select children that aren't in a spot", function(assert) {
    var done = assert.async();

    //Create a test controller
    var TestController = function() {
      this.base = FlokController; this.base(); self = this;

      self.init = function() {
        var matches = self.$sel("#hello");
        assert.equal(matches.length, 1, "Matches are 1");
        done();
      }
    }

    //Insert some HTML
    $("body").html("              \
      <div id='root'>             \
        <div id='test'>           \
          <div id='hello'></div>  \
        </div>                    \
      </div>                      \
    ");

    //Call the controllers init with a forged selector
    $sel = $("#test");
    var c = new TestController();
    c.__initialize__(0, $sel, {});
    c.init();
  });

  QUnit.test("Controller selector can-not select children that are in a spot", function(assert) {
    var done = assert.async();

    //Create a test controller
    var TestController = function() {
      this.base = FlokController; this.base(); self = this;

      self.init = function() {
        var matches = self.$sel("h1");
        assert.equal(matches.length, 0, "Matches are 0");
        done();
      }
    }

    //Insert some HTML
    $("body").html("                      \
      <div id='root'>                     \
        <div id='test'>                   \
          <div class='spot' id='hello'>   \
            <h1>Title</h1>                \
          </div>                          \
        </div>                            \
      </div>                              \
    ");

    //Call the controllers init with a forged selector
    $sel = $("#test");
    var c = new TestController();
    c.__initialize__(0, $sel, {});
    c.init();
  });

  QUnit.test("Controller selector can select spot themselves", function(assert) {
    var done = assert.async();

    //Create a test controller
    var TestController = function() {
      this.base = FlokController; this.base(); self = this;

      self.init = function() {
        var matches = self.$sel(".spot");
        assert.equal(matches.length, 1, "Matches are 1");
        done();
      }
    }

    //Insert some HTML
    $("body").html("                      \
      <div id='root'>                     \
        <div id='test'>                   \
          <div class='spot' id='hello'>   \
            <h1>Title</h1>                \
          </div>                          \
        </div>                            \
      </div>                              \
    ");

    //Call the controllers init with a forged selector
    $sel = $("#test");
    var c = new TestController();
    c.__initialize__(0, $sel, {});
    c.init();
  });

  QUnit.test("Controller selector can select children that aren't in a spot but a sub-controller of a spot", function(assert) {
    var done = assert.async();

    //Create a test controller
    var TestController = function() {
      this.base = FlokController; this.base(); self = this;

      self.init = function() {
        var matches = self.$sel("h1");
        assert.equal(matches.length, 1, "Matches are 1");
        done();
      }
    }

    //Insert some HTML
    $("body").html("                      \
      <div id='root'>                     \
        <div id='test'>                   \
          <div class='spot' id='hello'>   \
            <div id='test2'>              \
              <h1>Title</h1>              \
            </div>                        \
          </div>                          \
        </div>                            \
      </div>                              \
    ");


    //Call the controllers init with a forged selector
    $sel = $("#test2");
    var c = new TestController();
    c.__initialize__(0, $sel, {});
    c.init();
  });
});

