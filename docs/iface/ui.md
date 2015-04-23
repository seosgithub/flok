#User Interface (ui.js)

###Functions

`if_init_view(name, info)` - Create a view based on an agreed upon name for a `prototype` and pass it some `info`. Do not show the view yet.  Returns a hash containing  a key called `sp` with a `view pointer` and any named views will need to have the required keys as the view's name in the key and the value will be a pointer to that view.

`if_free_view(vp)` - Destroy a view with a `view pointer`.

`if_attach_view(vp, vsp)` - A request to embed a view (`vp`) into the top of a view or spot located at `vp`|`sp` provided during `if_init_view`.

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
