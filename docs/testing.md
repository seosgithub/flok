#Testing

##./spec layout
The `spec` folder contains all tests with the exception of **Driver** tests (See below for information).

  * `spec/`
    - `etc/`  - All tests that do not fit any categories.
    - `iface/`
      - `kern/` - All tests that *only* need the kernel (server) pipe.
      - `driver/` - All tests that *only* need the driver (client) pipe.
      -  `all/` - All tests that need both the kernel and driver pipe.
    - `kern/` - All tests for the kernel that do not need the pipe.
    - `lib/` - A folder of useful subroutines.
    - `env/` - Files that are automatically loaded at the beginning of each test that provide the environment.
      - `kern.rb` (for `./spec/kern/*_spec.rb`)
      - `iface.rb` (for `./spec/iface/**/*_spec.rb`)
      - `etc.rb` (for `./spec/etc/*_spec.rb`)


##Drivers
See the section on *Spec* in [Drivers](./drivers.md). Driver tests can be executed from the global rakefile by the convenience task `rake spec:driver PLATFORM=$PLATFORM`

##Kernel
Kernel tests only operate on the kernel and should **never** include tests that can be accomplished through using the kernel's pipe interface. Kernel tests are given a pre-build `V8` context that has the `application.js` loaded through `therubyracer`.

 * Running - `rake spec:kern PLATFORM=$PLATFORM`
 * Location - `./spec/kern/*_spec.rb`
 * Environment
   * `@ctx` - Access to a V8 runtime that has `application.js` preloaded. See [therubyracer](https://github.com/cowboyd/therubyracer)
   * `$PLATFORM` - Current platform the `application.js` was built for.
   * `$PWD` - `./`

##Interface
Interface tests are used for things that can be tested through either only the kernel pipe, driver pipe, or both.
  * Running - `rake spec:iface PLATFORM=$PLATFORM`
  * Location
    * `./spec/iface/kern` - Tests only need the server pipe
    * `./spec/iface/driver` - Tests only need the client pipe
    * `./spec/iface/all` - Tests need both pipes
  * Environment
   * `get_kern` - An `IO` pipe that talks to the kernel (server) as described in [Interactive](./interactive.md)
   * `get_driver` - An `IO` pipe that talks to the kernel (server) as described in [Interactive](./interactive.md)
   * `$PLATFORM` - The name of the platform of the driver and the parameters for the kernel.
   * `$PWD` - `./`

##Etc
Tests that do not fit into any of the categories (e.g. build output tests), should be placed in `./spec/etc`
These tests are runnable via `rake spec:etc PLATFORM=$PLATFORM`

  * Running - `rake spec:etc PLATFORM=$PLATFORM`
  * Location - `./spec/etc/`
  * Environment
   * `$PLATFORM` - The name of the platform of the driver and the parameters for the kernel.
   * `$PRODUCTS_PATH` - Location of the `application.js` file and `drivers` folder.
   * `$PWD` - `./`

##World & All

####World (Per platform)
The `rake spec:world PLATFORM=$PLATFORM` executes the following tests:
  1. The etc tests
  2. The kernel tests
  4. The interface tests
  5. The drivers tests

####All (All platforms)
The `rake spec` executes the same thing as `rake spec:world PLATFORM=$PLATFORM` but uses every platform automatically.
