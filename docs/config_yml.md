#config.yml
Config.yml stores the configuration, per platform, for each project. The `config.yml` file contains information relating to:
  1. What *modules* to include.  A *module* directive (`MODS`) tells flok what files to include from it's `$FLOK_GEM/app/kern/mods` directory. The specific platform driver may also read the modules list; but it is common for platform drivers to just have built-in modules that would be working if paired with the correct kernel modules interrupt handlers.
  2. What `defines` to use. A `define` shows up in the `@defines` array for kernel source code and may enable/disable sections of code. Documentation will indicate whether features need to have a `define` derective to be enabled. An example of this is simulation support of the `speech` module through `speech_sim`.
  3. `debug_attach` - A special directive used by the specs suite to understand the scheme used for the debugging server.

##Example
```yml
DEBUG:
  debug_attach: socket_io
  mods:
    - ui
    - event
    - net
    - segue
    - controller
    - debug
    - sockio
    - persist
    - timer
  defines:
    - mem_pager
    - sockio_pager
RELEASE:
  mods:
    - ui
    - event
    - net
    - segue
    - controller
    - sockio
    - persist
    - timer
  defines:
    - mem_pager
    - sockio_pager

```

##Where does a config.yml come from
The `config.yml` starts its life inside the flok gem's `$FLOK_GEM/app/drivers/$PLATFORM/config.yml` where it is later copied into new flok projects when created with `flok new` into your `$PROJECT/config/platforms/$PLATFORM/config.yml` via the `$FLOK_GEM/lib/flok/project_template` directory where an `erb` file called `config.yml` reads straight from the `$FLOK_GEM/app/drivers/$PLATFORM/config.yml` file.
