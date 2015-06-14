# Compliation

Compilation is handled by the `rake build:world PLATFORM=YOUR_PLATFORM FLOK_ENV=ENVIRONMENT` and then end result of that compliation is put in ./products/
Compilation *always* results in a `./products/$PLATFORM/application.js` file along with other files in `./products/$PLATFORM/drivers/` that
were deemed necessary by the platform driver `build` scripts. The environment can either be `DEBUG` or `RELEASE`.

### Build Order
*Unless otherwise stated, all files execute in alpha-numerical order. (`0foo.js` would execute before `1foo.js`).  Please use this convention only
as necessary.*

### Compilation is accomplished in the following order.

 1. `rake build` is run inside `./app/drivers/$PLATFORM` with the environmental variables set to BUILD_PATH=`./produts/$PLATFORM/driver` (and folder
 2. All js files in `./app/kern/config/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/1kern_config.js`
 3. All js files in `./app/kern/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/2kern.pre_macro.js`
 4. All js files in `./app/kern/pagers/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/3kern.pre_macro.js`
 5. All js files in `./products/$PLATFORM/glob/{2,3}kern.pre_macro.js` are run through `./lib/flok/macro.rb's macro_process` and then sent to `./products/$PLATFORM/glob/{2,3}kern.js`
 6. All js files are globbed from `./products/$PLATFORM/glob` and combined into `./products/$PLATFORM/glob/application.js.erb`
 7. Auto-generated code is placed at the end (like PLATFORM global)
 8. The module specific code in `./kern/mod/.*js` are added when the name of the file (without the js part) is mentioned in the `./app/drivers/$PLATFORM/config.yml` `mods` section and appended to `glob/application.js.erb`
 9. The compiled `glob/application.js.erb` file is run through the ERB compiler and formed into `application.js`

##Erb variables
All kernel source files support embedded ERB code like `<% if DEBUG %>Code<% end %>`. These files include:
  * `./app/kern/*.js`
  * `./app/kern/mod/*.js`
  * `./app/kern/services/*.js` - Services only support ERB in the javascript code sections

####Supported variables
  * `@debug` - Set to `true` when FLOK_ENV=DEBUG
  * `@release` - Set to `true` FLOK_ENV=RELEASE
  * `@mods` - The set of modules supported by this platform and build configuration
  * `@defines` - A hash that contains things under the `defines` section in a `config.yml`. Each item in the hash is `true`

```js
  //Example JS code for debug / release mode
  <% if @debug %>
    //JS Code for debug
  <% else %>
    //JS code for not debug mode
  <% end %>

  <% if @defines['spec_test'] %>
    //spec_helper_defines_spec_test
  <% end %>
```

####Spec Helpers
The file contained in the kernel `./app/kern/spec_helper.js` is used to test things like variable setting from `config.yml`
