#Test Service
This is the test service. Used for various specs

#Requests
  * `test_sync` - Will send you a synchronous response via the event `test_sync_res` that contains
    the same parameters that you sent
  * `test_async` - Will send you a synchronous response via the event `test_async_res` that contains
e.g.

###`test_sync`
```ruby
on_entry %{
  var info = {
    foo: "bar"
  }
  Request("test", "test_sync", info);
}

#This is called immediately
on "test_sync_res", %{
  test_sync_res_params = params; //params will equal {foo: "bar"}
}
```

###`test_async`
```ruby
on_entry %{
  var info = {
    foo: "bar"
  }
  Request("test", "test_async", info);
}

#This is called after the next int_event comes through via int_event_defer
on "test_async_res", %{
  test_async_res_params = params; //params will equal {foo: "bar"}
}
```

