# Compliation

Compilation is handled by the `rake build_world PLATFORM=YOUR_PLATFORM` and then end result of that compliation is put in ./products/
Compilation *always* results in a `./products/$PLATFORM/application.js` file along with other files in `./products/$PLATFORM/drivers/` that
were deemed necessary by the platform driver `build` scripts.

### Build Order
*Unless otherwise stated, all files execute in alpha-numerical order. (`0foo.js` would execute before `1foo.js`).  Please use this convention only
as necessary.*

### Compilation is accomplished in the following order.

 1. `rake build` is run inside `./app/drivers/$PLATFORM` with the environmental variables set to BUILD_PATH=`./produts/$PLATFORM/driver` (and folder
 2. All js files in `./app/kern/config/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/1kern_config.js`
 3. All js files in `./app/kern/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/2kern.js`
 4. All js files are globbed from `./products/$PLATFORM/glob` and combined into `./products/$PLATFORM/application.js`
 5. Auto-generated code is placed at the end (like PLATFORM global)
 6. The interrupt handlers in `./kern/int/.*js` are added where the glob is the same as `ifaces` array of `./app/drivers/$PLATFORM/config.yml`.  (We are importing only supported drivers, they should have the same name as the `./app/drivers/iface/.*`)
