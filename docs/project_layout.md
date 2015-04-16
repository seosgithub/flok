# Project layout
 * app/ - All actual pieces of the kernel code sit here.
   * app/drivers - Parts of (a) and (b)
     * app/drivers/interfaces - Generic interfaces that are suggested to be implemented.
     * app/drivers/$PLATFORM - Platform specific way to implement the interface. See *platform drivers* for information.
