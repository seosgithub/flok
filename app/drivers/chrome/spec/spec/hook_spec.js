QUnit.test("When a hook_event is received, it is relayed to the appropriate function handler if available", function(assert) {
  //Register a hook event handler
  onHookEvent("test", function(params) {
    test_hook_fired = true;
    test_hook_params = params;
  });

  onHookEvent("hello", function(params) {
    hello_hook_fired = true;
    hello_hook_params = params;
  });

  //Test two seperate hook events
  if_hook_event("test", {foo: "bar"});
  if_hook_event("hello", {hello: "world"});

  //Test an event that has no handler
  if_hook_event("no_such_handler", {test: "test"});

  assert.equal(test_hook_fired, true, "test hook was fired, got: ", test_hook_fired);
  assert.equal(JSON.stringify(test_hook_params), JSON.stringify({foo: "bar"}), "test hook was fired with params {foo: bar}, got: ", JSON.stringify(test_hook_params));
  assert.equal(hello_hook_fired, true, "hello hook was fired, got: ", hello_hook_fired);
  assert.equal(JSON.stringify(hello_hook_params), JSON.stringify({hello: "world"}), "hello hook was fired with params {foo: bar}, got: ", JSON.stringify(hello_hook_params));
});
