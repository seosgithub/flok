#User Interface (ui.js)

###Functions

`if_init_view(name, info)` - Create a view based on an agreed upon name for a `prototype` and pass it some `info`. Do not show the view yet.  Returns a hash containing  a key called `sp` with a `view pointer` and any named views will need to have the required keys as the view's name in the key and the value will be a pointer to that view.

`if_free_surface(vp)` - Destroy a view with a `view pointer`.

`if_detach_surface(vp)` - Remove a view from it's current view

`if_attach_surface(vp, vp)` - A request to embed a view (`vp`) into the top of a view or spot located at `vp` provided during `if_init_surface`.

------

## Overview 

This driver controls two things called a **view** and a **spot**. 

 1. **View** - A **view** holds your content.
 2. **Spot** - Views can have blank **Spot**s where other views can be placed.

## Examples
Here is a `view` named `login` in HTML5 (`chrome` driver)
```html
<!-- A login view -->
<div class='view' data-name='login'>
  <h1>Login</h1>
  <div class='form'>
    <input type='text' placeholder='email' />
    <input type='password' placeholder='password' />
    <button>
  </div>
</div>
```

Here is  a `view` named `nav_container` in HTML5 (`chrome` driver). This `view` has one `spot` called `content`.
```html
<!-- A nav view with a spot for content -->
<div class='view' data-name='nav_container'>
  <div class='nav_bar'>
    <a href='#'>Home</a>
    <a href='#'>About</a>
  </div>
  
  <div class='spot' data-name='content'></div>
</div>
```


###A note on free and remove
If `free` is called on a view, that view is always already detached. If a *view* receives `free`, that *view* must call `free` on all of it's children before itself.
