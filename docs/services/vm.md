#Virtual Memory (vm.js)
Virtual memory provides something akin to operating system virtual memory systems with an emphasis on the paging infrastructure. 

##Pages
Each page is a dictionary designed to be either a single node or a doubly linked list.
```ruby
page_example = {
  _next: "<<hash>>",
  _last: "<<hash>>",
  _key: "<<hash>>",
  entries: [
    {_key: "<<hash>>", ...},
    ...
  ],
  _ekey: "<<hash>>"
}
```
The page contains a `_next` and `_prev` hash pointer. These hashes point to pages stored in the same namespace as this page that logically are before
or after this page. What `before` and `after` means is up to the pager that controls the namespace. The `_key` is the hash-pointer of this page. The
`entries` is a list of anything; the only requirement is that each element in the list have a `UUID` `_key` and `_ekey` is a hash that changes
whenever anything in an entries changes.

###Configuration
The paging service may be configured in your `./config/services.rb`. You must set an array of pagers where each pager is responsible for a particular
namespace. See [VM Pagers](./vm/pagers.md) for more info.

```ruby
service_instance :vm, :vm, {
  :pagers => [
    {
      :name => "spec0",
      :namespace => "user",
      :options => {  //Passed to pager init function
      }
    }
  ]
}
```
Each pager can only be used once. In the future, using multiple copies of pagers would be a welcome addition. For multiple memory pagers, you may use the `mem0`, `mem1`, and `mem2` pagers.

  * Pager options
    * `name` - The name of the pager, this is used to create functions to each pager like `$NAME_read_sync`
    * `namespace` - The namespace of the pager, this is used during requests to the pager, each pager is bound to a namespace


###Spec helpers
The variable `vm_did_wakeup` is set to true in the wakeup part of the vm service.

##Requests

###`read`
Request (fault) a page of memory:
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
  * Event Responses
    * `read_res`
      * `ns` - Namespace of the fault
      * `key` - Key of the fault
      * `page` - Value of the fault

###`read_sync`
Request a page of memory synchronously *now*, does return:
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
  * Event Responses
    * `read_res`
      * `ns` - Namespace of the fault
      * `key` - Key of the fault
      * `page` - Value of the fault
  * Spec
    * Sets `vm_read_sync_called` to true

###`write`
Write to a page
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
    * `page` - The returned page
