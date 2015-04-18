# Project layout
 * app/ - All actual pieces of the kernel code sit here.
   * app/drivers - Parts of (a) and (b)
     * app/drivers/iface- Generic interfaces that are suggested to be implemented.
     * app/drivers/$PLATFORM/ - Platform specific way to implement the interface. See [platform drivers](./platform_drivers.md) for information.
   * app/kern - The remaining part, your app, the kernel, etc. all live under here.
     * app/kern/int.js - Interrupt handlers for drivers.
