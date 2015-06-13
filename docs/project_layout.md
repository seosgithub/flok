# Project layout
 * `app/` - All actual pieces of the kernel code sit here.
   * `app/drivers` - Parts of (a) and (b)
     * `app/drivers/iface` - Generic interfaces that are suggested to be implemented.
     * `app/drivers/$PLATFORM/` - Platform specific way to implement the interface. See [platform drivers](./platform_drivers.md) for information.
   * `app/kern` - The remaining part, your app, the kernel, etc. all live under here.
     * `app/kern/mod` - Interrupt handlers for drivers and associated code.
   * `/lib/kern/macro.rb` - Contains code that is called by `./lib/flok/build.rb` to run all kernel *js* code through as well as the `services_compiler`
     * This macro file provides various macros used in the kernel and services like `SEND`.
