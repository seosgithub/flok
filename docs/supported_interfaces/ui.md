#User Interface (ui.js)

###Functions

`if_init_surface(name, info)` - Create a surface based on an agreed upon name for a `prototype` and pass it some `info`. Do not show the surface yet.  Returns a `surface pointer`, abbreviated as `sp`.  A `surface pointer` is an opaque type that is platform defined.

`if_free_surface(sp)` - Destroy a surface with a `surface pointer`.

`if_embed_surface(source_sp, dest_sp, view_name)` - A request to embed a surface (`source_sp`) into another surface (`dest_sp`) in the `dest_sp`'s `view` named `view_name`. Animations can be added here, especially if you are embedding into a view that already contains a surface, in which case you need to swap the surfaces out (but not destroy the other). On completion of any animations, you need to call `int_embed_surface` which stands for **Interrupt: Embed Surface Complete**. If you are not doing animations, it is advised that you call `int_embed_surface` immediately in the same thread of execute that `if_embed_surface` was called on to avoid any graphical glitches or latency. Flok will suspend execution until `int_embed_surface` is received.

###Interrupts
`int_embed_surface` - An interrupt that signals that the surface has completed animations (or is just ready).

### Overview 

This driver controls the **semantics** of the visuals shown on screen.  There is no defined layouts, styles, or anything relating to rendering. There is however, a hierarchy description composed of two elements:

 1. Surfaces
 2. Views

###Surfaces
A `Surface` is somewhat analagous to View Controller's from iOS® with the exception that sa surface is embedded within other surfaces.

###Views
Views are *only* embedded within a surface.  You can have one view, one hundred views, or zero views within a `Surface`. Now you might be asking yourself,
wait, I thought you just said a *surface* is embedded in a *surface*, and now you're saying that a *view* is embedded within a *surface*?.

Yes, you read that correctly. A `View` only represents a blank area in a `Surface`; when you embed one `surface` in another `surface` you *must* say *where*. The *where*
is answered by the *view*.

Here's a concrete example to clear any remaining confusion.

![](../images/ui_surface_and_views.png)

In this diagram, you are seeing something akin to a `Navigation` controller that has a permanent navigation bar at the top. Inside this surface, there are two views named `topView`, and `btmView`.
This surface can then accept two sub-surfaces in those two views.

###Communication back to flok kernel
Each surface has a communication pipe connected to the kernel. For a typical user initiated event, like a button tap or gesture detection, the surface controller (platform defined), will notify that platform's `ui` driver through the `int_send_event(sp, event)` that an event has occurred and pass a valid `surface pointer` for the destination of the event.  Flok will then receive the `surface pointer` through the `pipe` subsystem and redirect the message to the `sc` subsystem (Surface Controller). Events going **to** the surface will be received by `if_handle_event(sp, event)`.  All these event related functions are in the [pipe interface](pipe.md)
