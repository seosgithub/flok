#find_view
`find_view(bp, spider_payload)` is a way to grab a set of sub-views of a **controller** and return a listing of base-pointers to the **views**. Originally
designed to allow selection of sub-views during transition interceptors (hooks). This would usually upset the abstraction barrier between controllers, which
are not supposed to know about their children, but for practical and performance reasons, we have decided to go with this style of implementation.

A spider payload is a specially crafted cascading hash (usually created statically by macros) that represents a multi-branch view-hierarchy *regular* expression
that is able to capture views on it's way through traversal.  It supports common operations of regular expressions such as *any* (`.`) and *one or more* (`+`) operator.
Thus, the spider payload is also able to select groups of views which is useful if you are doing a pushed view stack and need to know all except the top two views.

The following expressions are supported:

  * `.+` - This means *at least one* view. It returns a group.
  * `.` - This means *exactly one view*. It returns a single view.
  * `my_view` - This is simply a named view.

Additionally, expressions may contain a *named* capture by adding a `:$NAME` to the expression:
  
  * `.+:my_group`
  * `.:my_view`
  * `my_view:my_view`

An expression is then a selection tree:

```ruby
.
  my_view
    +
      my_other_sub_view:content
  my_other_view
```

> It is important to note that a selection will fail unless both all views in the selector are satisfied and that all views are satisfied have matching super-trees. In the above example, if there were two `my_view` descendents of our current controller we are selecting off, then `my_view` could not match half the selector on one descedent and then the other half on another descendent.
> 
> 
