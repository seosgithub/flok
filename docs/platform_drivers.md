#Platform Drivers
Each platform has it's own set of drivers. You do not have to implement *all* the drivers on a platform and you may create your own drivers to suite your own needs.  Platform drivers sit in `app/drivers/$PLATFORM` and *must* contain at least the following files.		+Plase see [[Platform Drivers|PlatformDrivers]].
  * app/drivers/$PLATFORM/Rakefile - You must at least have the tasks `test` and `build`.  Note that if you're writing custom drivers in your own project folder, this does not apply to you. Also, you must observe the rules in the platform's README.md		
  * app/drivers/$PLATFORM/README.md - A description of this platform driver, how to extend it with custom drivers, and how it is deployed correctly.		

During compliation all platform drivers must respect enviorenmental variables. For example, for $BUILD_PATH you can read this in your Rakefile via `ENV['BUILD_PATH']`.		
  * $BUILD_PATH    - The absolute file path (not including the filename) of where to put build files.		
  * $BUILD_JS_NAME - The filename of the javascript file to output to the $BUILD_PATH.		

Your build path may contain additional files as you see fit.  These files will be available in the user's project in `./products/$PLATFORM/xxxxx` with the exception of the javascript outputfile which will be merged at the beginning of the complete source.		
  
Additionally, the full application contains the function `lsdrivers()` which will return an array of all the drivers that are supported`