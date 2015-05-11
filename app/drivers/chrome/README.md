# CHROME driver
This driver supports an internet browser.

# Installing / Implementation
At the completion of the build, the driver directory, typically `products/$PLATFORM/driver` will contain a `chrome.js` file.  This must be included
before your `application.js` file.

### HTML conventions
There is excatly (1) divider that is used to place everything inside of that is visible.  This divider *must* have the following HTML code:
```html
<!-- Mount point for view hierarchy, fully managed, do not touch -->
<div id='root'></div>

<div id='prototypes' style='display: none'>
  <!-- Insert your prototypes inside here -->
</div>

```

### Adding a surface prototype
You may add surface prototypes like so under your #surface-prototypes divider
```html
<!-- Insert your prototypes inside here -->
<div id='prototypes' style='display: none'>
  <!-- A tab container with a sub-view -->
  <div class='view' data-name='nav_container'>
    <h1>Title</h1>
    <button>Back</button>
    <hr />
    <div class='spot' data-name='main'>
  </div>

  <!-- A login view -->
  <div class='view' data-name='login'>
    <input type='text' placeholder='email' />
    <input type='text' placeholder='password' />
    <button>Login</button>
  </div>
</div>
```

### Binding a Controller to a view
You create a constructor for a controller
```js
//Constructor for a controller that will automatically bind to a surface with the attribute 'data-name=tab_controller'
var TestController = function() {
  this.base = FlokController; this.base();

  this.action = function(from, to) {
    this.send("spec", {from: from, to:to});
  }

  this.event = function(name, info) {
    this.send("spec", {name:name, info:info})
  }
}

//Register the new controller
$(document).ready(function() {
  regController("__test__", TestController);
});

```
