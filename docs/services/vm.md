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
namespace.

##Requests

###`read`
Request (fault) a page of memory:
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
  * Event Responses
    * `page_fault_res`
      * `ns` - Namespace of the fault
      * `key` - Key of the fault
      * `entries` - Value of the fault

###`read_sync`
Request a page of memory synchronously *now*, does return:
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
  * Event Responses
    * `page_fault_res`
      * `ns` - Namespace of the fault
      * `key` - Key of the fault
      * `value` - Value of the fault

###`write`
Write to a page
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
    * `entries` - The new entries of the page, if the page dosen't exist, it will be overwritten
