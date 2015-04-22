#User Interface (ui.js)

###Functions

`if_init_view(name, info)` - Create a view based on an agreed upon name for a `prototype` and pass it some `info`. Do not show the view yet.  Returns a hash containing  a key called `sp` with a `view pointer` and any named views will need to have the required keys as the view's name in the key and the value will be a pointer to that view.

`if_free_surface(vp)` - Destroy a view with a `view pointer`.

`if_detach_surface(vp)` - Remove a view from it's current view

`if_attach_surface(vp, vp)` - A request to embed a view (`vp`) into the top of a view or area located at `vp` provided during `if_init_surface`.

------

## Overview 

This driver controls the **semantics** of the visuals shown on screen.  There is no defined layouts, styles, or anything relating to rendering. There is however, a hierarchy description composed of two elements:

 1. **View** - A **view** holds your content.
 2. **Area** - Views can have blank **areas**s where other views can be placed.

## Analogy
Here is an *analougy* in HTML. **This is not the way it's actually defined, the code here is never actually used in flok, but something similar is**
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

```html
<!-- A nav view with an area for content -->
<div class='view' data-name='nav_container'>
  <div class='nav_bar'>
    <a href='#'>Home</a>
    <a href='#'>About</a>
  </div>
  
  <div class='spot' data-name='content'></div>
</div>
```


###A note on free and remove
The `if_free_surface` must always be preceeded by a `if_detach_surface` if the surface is already attached. Failure to do so is undefined.
Additionally, `detach` and `free` will only be called on the root of the hierarchy and should effect all children. Most platforms have a reference
counting implementation that can handle this, like `ARC` on iOS and the `DOM` on HTML5. For other platforms, there is planned support for a compilation
hint that will shim this driver to automatically destroy and detach surfaces in reverse hierarchical order.
