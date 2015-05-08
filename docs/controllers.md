#Controllers
Controllers are a lot like the controllers from `MVC` triads. They are the heart of your user-defined behavior in the same way rails controllers define your web-application.

###Writing them
Controllers have two parts, `controller` and `action`.  They are defined in ruby files like so:

```ruby
controller "nav_controller" do
  view "nav_container"

  action "index" do
    on_entry %{
    }
  end
end
```

Of course, this isn't really ruby. Ruby is used for pre-compilation; the generated JS code produced is a static structure that has no callbacks or closures.
The javascript code is contained within `%{}`.  This is ruby's way of doing multiline strings. You may also use `""` if you prefer like `on_entry "<<js code>>"`

Each controller has a name and it defines 1 root view. In this case, the controller is named `nav_controller` and has a root view named `nav_container`.

###Internals
This controller is put inside the `ctable` for all the things that don't change. see [datatypes](./datatypes.md) for information on the layout of the ctable 
for each controller.

In order for changes to be represented in a controller, a controller must be *initialized*. Unlike rails, Flok allows you to use many controllers within one-another,
and many instances of the same controller if you wish. 

Controller initialization is done via `_embed` or the `embed` macro if you are inside a controller. Embedding
  1. Requests a set of sequential pointers via `tels`, `n(spots)`.  `main` is always a spot, so there is always at least one pointer. The first pointer is the base.
  2. Initializes the root view of the controller with the base pointer and retrieve the spots array from the controller `main` + whatever you declared in `spots`
  3. Attaches that view to the `view pointer` (which is a tele-pointer) given in the embed call.
  4. Sets up the view controller's info structure.
  5. Explicitly registers the view controller's info structure with the `root view base pointer` via `tel_reg_ptr(info, base)`
  6. Invokes the view controllers `on_entry` function with the info structure.
