#Driver Interface

**This file contains a lot of information duplicated in [platform drivers](./platform_drivers.md)**

There is no standard communication protocol or interface for drivers.  The driver stack operates by 

1. The platform drivers bundle, e.g. `./app/drivers/CHROME/` will declare it's `ifaces` in `config.yml`
2. During compilation, the `application.js` file is embedded with `IFACES`
3. Your application may now use `IFACES` to dynamically alter it's behavior to be suitable.

#What are Driver Interfaces?
An interface is just a javascript file with a set of function definitions a-lot like C header files.  They are located in `./app/drivers/iface`.  These are not actually used in your compiled program but serve as a reference to other developers on how to implement your interface.  We have future plans to use the interface files themselves so please, please, please... implement the interface files.

Here is an example interface file for a printer.

```js
//./app/drivers/iface/printer.js
//This interface provides printing capabilities

//Print a document out from a string, returns a opaque print job pointer. (job)
function if_print(str) {}

//Cancel a currently queued print.
function if_cancel_print(job) {}
```

**Note the 'if_' infront of each function's name, this stands for interface and must be used on all interface functions**.

As you can see, there is no implementation in this code.  This is not just an abbreviated example, this is the entire interface file.  For each platform, you will now have to do two things to use this driver.

1. You must add this driver to your driver's `config.yml` file in the `ifaces`.  In this case, you would add  `printer` to the `ifaces` array.
2. You must ensure that when the application makes a call to any functions declared in the interface, they are handled appropriately.  For full javascripts systems (like HTML5), this is accomplished by simply defining the needed functions.  For other platforms that use native code, the functions are usually implemented by exporting a native function into the javascript space.

Here is an example of an iOS implementation of the print driver, specifically the `if_print` function.
```swift
let if_print: @objc_block String -> Int = { str in
    var mutableString = NSMutableString(string: str) as CFMutableStringRef
    /*
      -------------------------
      Execute print code here
      -------------------------
    */
    
    return printPointer;    
}

context.setObject(unsafeBitCast(if_print, AnyObject.self), forKeyedSubscript: "if_print")
```
[Courtesy goes to NSHpister](http://nshipster.com/javascriptcore/)

3.  You must add any necessary *interrupts* when you want your native enviorment to call back to the kernel.  These are defined in `./app/kern/iface/$IFACE.js`.  All interrupts have the nomenclature of `int_XXXXX`.
4.  If you are publishing this on the core flok distribution, please add necessary pages to [Supported Interfaces](./supported_interfaces.md)

#Writing good driver interfaces
A good driver interface, and driver for that matter, implement no logic beyond what is necessary for the completion of that action.  There are exceptions to this rule and they usually are around performant code where it is necessary to use native drivers to number crunch, parse, etc. 

#States & Opaque Pointers
If it can be avoided, it is best to avoid using any state information in your drivers.  Opaque pointers can assist with this.  E.g. the `if_print` function as described above returns an `opaque pointer` that is compatible with `if_cancel_print`.  The driver that implements this interface is free to implement opaque pointers in any way that seems sensible. The only restriction is that the pointers are able to be read by javascript itself and regurgetated in a useful form. Try to avoid using a hash table if possible if you can directly feed native pointers as there are performance benefits and less state information.

------


#Dynamic Drivers
Flok does not currently support dypnamic driver attachment or probing like many operating systems, e.g. Freebsd's `kldload`.  If you need the ability to probe dynamically, for example, some devices support *LTE Bleuetooth Activity Trackers*, then it would be best to create a driver interface called `sensors` which would tell you if any `LTE Bluetooth Activity Trackers` are available.


