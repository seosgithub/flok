#Virtual Memory (vm.js)
Virtual memory provides something akin to operating system virtual memory systems with an emphasis on the paging infrastructure.  Unlike an operating system, flok has the concept of a grand-unified namespaced address space that extends the concepts of caching and semantics across asynchronous and even networked systems.  This vm systems is increadibly powerful because it allows you to create custom paging devices; this allows you to use one set of semantics to perform very complicated activities like pulling a news feed or list; having that news feed cached to disk automatically; etc.

Additionally, flok introduces a notification system that works with the demand paging schemes and caching schemes that allow you to grab data *now* and then be notified whenever a fresh copy is available from the server.

Each pager belongs to a *namespace*; page faults hit a namespace and then the pager takes over. The pager can choose to service a request; or even throw an exception if a certain semantic is not supported in it's namespace; for example, you may want to disable write semantics for a network pager you called `net` because you expect people to make ordinary network requests.

Fun aside; Because of the hashing schemantics; this paging system solves the age old problem of ... how do you show that data has changed *now* when to be assured that you have perferctly synchronized data with the server?;... you need to do a 3-way handshake with the updates.  You could have a network server pager that supports writes but dosen't forward those to the network. That way, you can locally modify the page and then if the modifications were guessed correctly, the server would not even send back a page modification update! (Locally, the page would have been propogated as well).  In the meantime, after modifying the local page, you would send a real network request to the server which would in turn update it's own paging system but at that point, the server would check in with you about your pages, but miraculously, because you gussed the updated page correctly, no modifications will need to be made. You could even purposefully put a 'not_synced' key in and actually show the user when the page was correctly synchronized.

##Pages
Each page is a dictionary containing a list of entries.
```ruby
page_example = {
  _head: <<UUID STR>>,
  _next: <<UUID STR>,
  _uuid: <<UUID STR>,
  entries: [
    {_uuid: <<UUID STR>>, _timestmap: <<epoch_milliseconds STR>>},
    ...
  ],
  _hash: <<CRC32 >
}
```

  * `_head (optional)` - An optional pointer that indicates a *head* page. The head pages are special pages that contain 0 elements in the entries array, no `_head` key, and `_next` points to the *head* of the list. A head page might be used to pull down the latest news where the head will tell you whether or not there is anything left for you to receive.
  * `_next (optional)` - The next element on this list. If `_next` is non-existant, then this page is the endpoint of the list.
  * `_uuid` - The name of this page. Even if every key changed, the `_uuid` will not change. This is supposed to indicate, semantically, that this page still *means* the same thing.  For example, imagine a page.  If all entries were to be **removed** from this page and new entries were **inserted** on this page, then it would be semantically sound to say that the entries were **changed**.
  * `entries` - An array of dictionaries. Each element contains a `_uuid` that is analogous to the page `_uuid`. (These are not the same, but carry the same semantics).  Entries also have a `_timestamp` based on their creation or edit time from the unix epoch milliseconds.
  * `_hash` - All entry `_uuid's`, `_next`, the page `_uuid`, and `head` are hashed togeather. Any changes to this page will cause this `_hash` to change which makes it a useful way to check if a page is modified and needs to be updated. The hash function is an ordered CRC32 function run in the following order.  See [Calculating Page Hash](#calculating_page_hash).

------

## <a name='calculating_page_hash'></a>Calculating Page Hash
The `_hash` value of a page is calculated in the following way:
  1. `z = CRC32(_head)`
  2. `z = CRC32(_next+z)`
  3. `z = CRC32(_uuid+z)`
  4. `z = CRC32(entriesN._timestamp+z)` where N goes through all entries in order.

The `_hash` value 

------

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
Request (fault) a page of memory, note that this can cause multiple `read_res` because of `read-sync-notify` where an immediate read from cache will trigger a synchronization which inturn may trigger a notification.
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `key` - The 'address' of the memory in the namespace
  * Event Responses
    * `read_res`
      * `ns` - Namespace of the fault
      * `key` - Key of the fault
      * `page` - Value of the fault

###`read_sync`
Request (fault) a page of memory synchronously, note that this can cause multiple `read_res` because of `read-sync-notify` where an immediate read from cache will trigger a synchronization which inturn may trigger a notification.
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

##Methods
`vm_cache_write(ns, key, spec0_data[key])` - Save a piece of data to the cache memory
