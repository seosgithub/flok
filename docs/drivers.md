#Drivers
A driver in flok is for one specific platform. The driver lives in the `./app/drivers/$PLATFORM` folder.
This folder is required to have a `config.yml` and a `Rakefile`.  Everything else that goes in this folder is up to the implementor.

## config.yml
Driver configuration file.  Contains the following keys:
  * `mods` - A list of module names this driver supports. See [Modules](./modules.md) for details.

## Rakefile
Contains the following tasks:
  * `build` - A request for this driver to build it's files into the folder `$BUILD_PATH`
  * `spec`  - Run any unit tests that the implementor deems necessary
  * `pipe`  - Establish a 2-way pipe on standard io to a javascript context that this driver defines.

## Minimum interface
Every driver *must* be able to accept a js function call for `if_dispatch` (See [Messaging](./messaging.md)). The `if_dispatch`
implementation should handle messages appropriately so that the messages it receives can be fulfilled as stated in the modules
contract.
