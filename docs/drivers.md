#Drivers
A driver in flok is for one specific platform. The driver lives in the `./app/drivers/$PLATFORM` folder.
This folder is required to have a `config.yml` and a `Rakefile`.  Everything else that goes in this folder is up to the implementor.

## config.yml
Driver configuration file.  Contains the following keys:
  * `$ENVIRONMENT` - Can either be `RELEASE` or `DEBUG`
    * `mods` - A list of module names this driver supports. See [Modules](./modules.md) for details.

```yml
DEBUG:
  mods:
    ui
    debug
RELEASE:
  mods:
    ui
```

## Rakefile
Contains the following tasks:
  * `build` - A request for this driver to build it's files into the folder `$BUILD_PATH`
  * `spec`  - Run any unit tests that the implementor deems necessary that do not need the pipe. Given `$BUILD_PATH`
  * `pipe`  - Establish a 2-way pipe on standard io where input goes to `if_dispatch` and `int_dispatch` goes to output.  

## Minimum interface
Every driver *must* export `if_dispatch` into the context managing `application.js` (See [Messaging](./messaging.md)). The driver should then handle `if_dispatch` and it's implementation should handle messages appropriately so that the messages it receives can be fulfilled as stated in the modules
contract. The driver should also offer some way to call `int_dispatch` *inside* the `application.js` context from the outside world.

## Spec (Testing)
Driver tests are chosen by the platform implementor.  The only requriements for a driver test are that it be run when `rake spec` is executed within the `./app/driver/$PLATFORM/` folder. These tests should **never** do anything that can be tested by only using the driver's pipe interface. Tests that can be done through the pipe interface should be done through the **Driver Interface** tests (See the section on *Interface* in [Testing](./testing.md).

  * Running - `rake spec`
  * Location - `./app/drivers/$PLATFORM/`
  * Environment
    - `$BUILD_PATH` - The same folder the driver was given during `build`
    - `$PWD` - `./app/drivers/$PLATFORM/`

## Debug View & Controller
When a driver receives a `if_init_view` it cannot handle because the view is not something it has been programmed to understand, (typically through a template system), that driver is suggested to show a `debug` view if 
the driver is built with the environmental variable `$FLOK_ENV` set to `DEBUG` and the `debug` module is present. The *debug* view should have one associated *debug* controller for all debug views that does the same thing.

The *debug* view and controller should show something along the lines of:
  * The controller name - This is given in `if_init_controller`
  * The current action name - This is given in the `action` event `to` field.
  * The last event received - You can capture this information in your custom event handler.
  * The context information - This is passed in `if_init_controller` and should be accesssible in your view controller via `context`
  * N Spaces for each attempted attachment of a view controller - When `if_init_view` is called, it has a list of spaces. Use these to dynamically create them.
  * A list of buttons where each button triggers an event associated with the current action - This is set with `if_debug_assoc(controller_name, "action_events", [..])`
