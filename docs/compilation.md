# Compliation

Compilation is handled by the `rake build:world PLATFORM=YOUR_PLATFORM` and then end result of that compliation is put in ./products/
Compilation *always* results in a `./products/$PLATFORM/application.js` file along with other files in `./products/$PLATFORM/drivers/` that
were deemed necessary by the platform driver `build` scripts.

### Build Order
*Unless otherwise stated, all files execute in alpha-numerical order. (`0foo.js` would execute before `1foo.js`).  Please use this convention only
as necessary.*

### Compilation is accomplished in the following order.

 1. `rake build` is run inside `./app/drivers/$PLATFORM` with the environmental variables set to BUILD_PATH=`./produts/$PLATFORM/driver` (and folder
 2. All js files in `./app/kern/config/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/1kern_config.js`
 3. All js files in `./app/kern/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/2kern.pre_macro.js`
 4. All rb files inside `./app/kern/services/` are globbed into `./products/$PLATFORM/glob/kern_services.rb`
 5. `./products/$PLATFORM/glob/kern_serivces.rb` is processed via `Flok::Services` and then exported as `./products/$PLATFORM/glob/kern_services.pre_macro.js`
 6. All js files in `./products/$PLATFORM/glob/2kern.pre_macro.js` are run through `./app/kern/macro.rb's macro_process` and then sent to ./products/$PLATFORM/glob/2kern.js
 7. All js files in `./products/$PLATFORM/glob/kern_services.pre_macro.js` are run through `./app/kern/macro.rb's macro_process` and then sent to ./products/$PLATFORM/glob/kern_services.js
 8. All js files are globbed from `./products/$PLATFORM/glob` and combined into `./products/$PLATFORM/application.js`
 9. Auto-generated code is placed at the end (like PLATFORM global)
 10. The module specific code in `./kern/mod/.*js` are added when the name of the file (without the js part) is mentioned in the `./app/drivers/$PLATFORM/config.yml` `mods` section.
