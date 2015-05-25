#Intercept
The intercept module supports the animation system by allowing you to hijack an action change for a particular view controller.

Typical Example:
```js
intercept("my_controller", "start_action", "to_action", function($sel) {
  $sel.find("#content").css("left", "40%");
  $sel.find("#tab-bar").css("left", "0%");

  cd("../*/")
});
```

The actual code used to define an interceptor function is dependent on the platform.

An interceptor is defined like as follows:
```
transition "blah" do
  #Define the context
  controller "blah"
  when "a" => "b"

  path :home, "../../0"
  path :about, "./1"
end
```
