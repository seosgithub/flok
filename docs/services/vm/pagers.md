#VM Pagers
Here is a list of default pagers for the vm system.

=======

##How to make your own pager
A new pager can be created by adding the pager to the `./app/kern/services` folder or `./app/services/pagers` if you are in a project.

**For all operations that are cacheable, you must write to vm_cache[ns][key]**

Each pager must implement the following functions:
  * `init(options)` - Initialize a pager structure, passes options given in vm options hash for this pager in `./config/services.rb`
  * `read(bp, key)`
  * `read_sync(bp, key)`
  * `write(key, page)`

##Caching
For pagers that wish to have their pages cached, they must set their `read` and `read_sync` to write to vm_cache.
```js
  vm_cache_write(ns, key, spec0_data[key])
```

##Default pagers
###`mem` - Default memory pager
This pager dosen't do anything beyond allow you to set pages, write to them, and delete them.
  * Supported operations
    * `read`
    * `read_sync`
    * `write`

###`sockio` - Network pager
  * Supported operations
    * `read`

###Spec pagers
###`spec0` 
This pager assists with specs in ./spec/kern/vm_service_spec.js
  * Supported operations
    * `init(options)` - Will set the `spec0_init_options` to be what ever options it got.
    * `read` - Will set the `spec0_read_sync_called` to be true.
    * `read_sync` - Will set the `spec0_read_sync_called` to be true.
###`spec1` 
This pager is designed to test the read-sync-notify notification system. When this function is first called,
it will return 'a' for any value. The second call to read will return `b`.
  * Supported operations
    * `init(options)`
