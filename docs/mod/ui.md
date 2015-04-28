#User Interface (ui.js)

###Functions

`if_init_view(name, info, tp_base, *tp_targets)` - Create a view based on an agreed upon name for a `prototype` and pass it some `info`. Do not show the view yet.  `tp_targets` will look like `["main", "contentA", ...]` where everything after `root` is a spot.
```js
(main)>if_init_view('nav_container', {title: "Home"}, 333, ["root", "content"]);
```

`if_free_view(vp)` - Destroy a view with a `view pointer`.

`if_attach_view(vp, p)` - A request to embed a view (`vp`) into the top of a view or spot located at `vp`|`sp` provided during `if_init_view`. If `p` is a `view pointer`, then `vp` is placed **ontop** of `p`.  If `p` is a `spot pointer`, then `vp` is placed **inside** of `p`.  If *p* is 0, then you should place this **inside** of the root view.

`if_detach_view(vp)` - Remove a view from it's current view

------

## Overview 

This driver controls two things called a **view** and a **spot**. 

 1. **View** - A **view** holds your content.
 2. **Spot** - Views can have blank **Spot**s where other views can be placed.

## Examples
Here is an example for the `chrome` driver of a live view built from two views.
![](../images/view_and_spot.png)



###A note on free and remove
If `free` is called on a view, that view is always already detached. If a *view* receives `free`, that *view* must call `free` on all of it's children before itself.
