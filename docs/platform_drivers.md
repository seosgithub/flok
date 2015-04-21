#Platform Drivers
Each platform has it's own set of drivers. You do not have to implement *all* the drivers on a platform and you may create your own drivers to suite your own needs.  Platform drivers sit in `app/drivers/$PLATFORM` and *must* contain at least the following files.
  
During compliation all platform drivers must respect enviorenmental variables. For example, for $BUILD_PATH you can read this in your Rakefile via `ENV['BUILD_PATH']`.		
  * $BUILD_PATH    - The absolute file path (not including the filename) of where to put build files.		

Your build path may contain additional files as you see fit.  These files will be available in the user's project in `./products/$PLATFORM/xxxxx` with the exception of the javascript outputfile which will be merged at the beginning of the complete source.		
  
Additionally, the full application contains the function `IFACES` which will return an array of all the drivers that are supported`

### $PLATFORM
The 'platform' naming convention is for it to be completely upper-case.

### Testing
Please see [Testing](testing.md) for informaiton on how testing is accomplished.

### Files
  * ./Rakefile - You must at least have the tasks `build` and `pipe`. Optionally, you may have the task `spec`.
  * ./README.md - A description of this platform driver, how to extend it with custom drivers, and how it is deployed correctly.		
  * ./config.yml - Must contain a list of the supported interfaces for a driver.

### config.yml
Your configuration must have a `ifaces` key. This is an array of the supported interfaces.  The interface name is just the filename located in
`./app/drivers/iface/.*.js`.  In the example below there is a `ui.js` and `network.js` in the `./app/drivers/iface/` folder.
```yml
ifaces:
  - ui
  - network
```
You may access this list in a compiled kernel via `IFACES`. See [Interface section on globals](interface.md) for more info.

### Platform specifics
See the ./app/drivers/$PLATFORM/README.md file for information on each individual platforms specifics.

### Interfaces
See [Interfaces](driver_interface.md) for more information.
