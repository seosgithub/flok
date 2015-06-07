#VM Pagers
Here is a list of default pagers for the vm system.

=======

##How to make your own pager
A new pager can be created by adding the pager to the `./app/kern/services` folder or `./app/services/pagers` if you are in a project.

Each pager must implement the following functions:
  * `read(bp, key)`
  * `read_sync(bp, key)`
  * `write(bp, key, page)`

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
