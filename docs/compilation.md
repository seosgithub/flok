# Compliation

Compilation is handled by the `rake build platform=z` and then end result of that compliation is put in ./products/
Compilation *always* results in a `./products/$PLATFORM/appliaction.js` file along with other files in `./products/$PLATFORM/` that
were deemed necessary by the platform driver `build` scripts.

### Build Order
*Unless otherwise stated, all files execute in alpha-numerical order. (`0foo.js` would execute before `1foo.js`).  Please use this convention only
as necessary.*

### Compilation is accomplished in the following order.
 * All files in `./app/config/.*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/0config.js`
 * `rake build` is run inside `./app/drivers/$PLATFORM` with the environmental variables set to BUILD_PATH=`./produts/$PLATFORM/driver` (and folder
 * created)
 * All js files in `./app/libkern/` are globbed togeather and sent to `./products/$PLATFORM/glob/1libkern.js`
 * All js files in `./app/kern/` are globbed togeather and sent to `./products/$PLATFORM/glob/2kern.js`
 * All js files in `./app/user/config/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/3user_config.js`
 * All js files in `./app/user/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/4user.js`
 * All js files are globbed from `./products/$PLATFORM/glob` and combined into `./products/$PLATFORM/application.js`


 At the end, you end up with a standalone JS file called `./products/$PLATFORM/application.js` and platform dependent code in
 `./products/$PLATFORM/driver` that you must implement based on that drivers readme
