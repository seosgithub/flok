#Drivers
A driver in flok is for one specific platform. The driver lives in the `./app/drivers/$PLATFORM` folder.
This folder is required to have a `config.yml` and a `Rakefile`.  Everything else that goes in this folder is up to the implementor.

## config.yml
Driver configuration file.  Contains the following keys:
  * `mods` - A list of module names this driver supports. See [Modules](./modules.md) for details.

## Rakefile
Contains the following tasks:
  * `build` - A request for this driver to build it's files into the folder `$BUILD_PATH`
  * `spec`  - Run any unit tests that the implementor deems necessary that do not need the pipe. Given `$BUILD_PATH`
  * `pipe`  - Establish a 2-way pipe on standard io where input goes to `if_dispatch` and `int_dispatch` goes to output.  

## Minimum interface
Every driver *must* be able to accept a js function call for `if_dispatch` (See [Messaging](./messaging.md)). The `if_dispatch`
implementation should handle messages appropriately so that the messages it receives can be fulfilled as stated in the modules
contract. The driver should also offer some way to call `int_dispatch` from outside the context.

## Spec (Testing)
Driver tests are chosen by the platform implementor.  The only requriements for a driver test are that it be run when `rake spec` is executed within the `./app/driver/$PLATFORM/` folder. These tests should **never** do anything that can be tested by only using the driver's pipe interface. Tests that can be done through the pipe interface should be done through the **Driver Interface** tests (See the section on *Interface* in [Testing](./testing.md).

  * Running - `rake spec`
  * Location - `./app/drivers/$PLATFORM/`
  * Environment
    - `$BUILD_PATH` - The same folder the driver was given during `build`
    - `$PWD` - `./app/drivers/$PLATFORM/`
