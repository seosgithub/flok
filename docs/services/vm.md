#Virtual Memory (vm.js)
Virtual memory provides something akin to operating system virtual memory systems with an emphasis on the paging infrastructure.  Unlike an operating system, flok has the concept of a grand-unified namespaced address space that extends the concepts of caching and semantics across asynchronous and even networked systems.  This vm systems is increadibly powerful because it allows you to create custom paging devices; this allows you to use one set of semantics to perform very complicated activities like pulling a news feed or list; having that news feed cached to disk automatically; etc.

Additionally, flok introduces a notification system that works with the demand paging schemes and caching schemes that allow you to grab data *now* and then be notified whenever a fresh copy is available from the server.

Each pager belongs to a *namespace*; page faults hit a namespace and then the pager takes over. The pager can choose to service a request; or even throw an exception if a certain semantic is not supported in it's namespace; for example, you may want to disable write semantics for a network pager you called `net` because you expect people to make ordinary network requests.

Fun aside; Because of the hashing schemantics; this paging system solves the age old problem of ... how do you show that data has changed *now* when to be assured that you have perferctly synchronized data with the server?;... you need to do a 3-way handshake with the updates.  You could have a network server pager that supports writes but dosen't forward those to the network. That way, you can locally modify the page and then if the modifications were guessed correctly, the server would not even send back a page modification update! (Locally, the page would have been propogated as well).  In the meantime, after modifying the local page, you would send a real network request to the server which would in turn update it's own paging system but at that point, the server would check in with you about your pages, but miraculously, because you gussed the updated page correctly, no modifications will need to be made. You could even purposefully put a 'not_synced' key in and actually show the user when the page was correctly synchronized.

##Pages
Each page is a dictionary containing a list of entries.
```ruby
page_example = {
  _head: <<uuid STR>>,
  _next: <<uuid STR>,
  _id: <<uuid STR>,
  entries: [
    {_id: <<uuid STR>>, _timestmap: <<epoch_milliseconds STR>>},
    ...
  ],
  _hash: <<CRC32 >
}
```

  * `_head (optional)` - An optional pointer that indicates a *head* page. The head pages are special pages that contain 0 elements in the entries array, no `_head` key, and `_next` points to the *head* of the list. A head page might be used to pull down the latest news where the head will tell you whether or not there is anything left for you to receive.
  * `_next (optional)` - The next element on this list. If `_next` is non-existant, then this page is the endpoint of the list.
  * `_id` - The name of this page. Even if every key changed, the `_id` will not change. This is supposed to indicate, semantically, that this page still *means* the same thing.  For example, imagine a page.  If all entries were to be **removed** from this page and new entries were **inserted** on this page, then it would be semantically sound to say that the entries were **changed**.
  * `entries` - An array of dictionaries. Each element contains a `_id` that is analogous to the page `_id`. (These are not the same, but carry the same semantics).  Entries also have a `_timestamp` based on their creation or edit time from the unix epoch milliseconds.
  * `_hash` - All entry `_id's`, `_next`, the page `_id`, and `head` are hashed togeather. Any changes to this page will cause this `_hash` to change which makes it a useful way to check if a page is modified and needs to be updated. The hash function is an ordered CRC32 function run in the following order.  See [Calculating Page Hash](#calculating_page_hash).

------

## <a name='calculating_page_hash'></a>Calculating Page Hash
The `_hash` value of a page is calculated in the following way:
  1. `z = crc32(0, _head)`
  2. `z = crc32(z, _next)`
  3. `z = crc32(z, _id)`
  4. `z = crc32(z, entriesN._timestamp)` where N goes through all entries in order.

Assuming a crc function of `crc32(seed, string)`

------

##Configuration
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
Each pager can only be used once. In the future, using multiple copies of pagers would be a welcome addition. If you need to duplicate functionality of a pager,
you will want to copy your pager into a seperate piece of code and rename it so that it contains unique function names and variables, e.g. `my_pager0_read()` -> `my_pager1_read()`

  * Pager options
    * `name` - The name of the pager, this is used to create functions to each pager like `$NAME_read_sync`
    * `namespace` - The namespace of the pager, this is used during requests to the pager, each pager is bound to a namespace
    * `options` - A hash that is given to the pager's init function.


##Requests

###`watch`
This is how you asynchronously **read a page** and request notifications for any updates to a page. When you first watch a page, you will receive a local cached copy if it is available. For the first watch of a page, pagers will typically update that page so you will get another read as soon as it is available.  For pages that are not locally cached, you will have to wait for a response.

**To re-iterate, flok has a different concept of what constitutes a read. Flok does not distinguish between a read and the want to know about changes to a page. Flok considers controllers that have just watched a page to have an invalid copy of that page, and thus need to be notified that the page has changed for first read**
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `id` - Watching the page that contains this in the `_id` field
  * Event Responses
    * `read_res` - Whenever a change occurs to a page or the first read.
      * `ns` - Namespace of the fault
      * `first` - A boolean that indicates whether this page was ever received on `page_update` before. i.e. is it a change after we were already given this page previously in a `page_update` for this receiver?
      * `page` - A dictionary object that is a reference to the page. This should be treated as immutable as it is a shared resource.

###`read_sync`
Request a page of memory synchronously. This will only trigger one `read_res`. If a page does not exist, that should be considered an error. You would normally use this with a blank pager that relies on the cache system to recover data that is either resident in RAM or load it from disk. For example, maybe you would like to display the user's name when they first login without waiting.
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `id` - Watching the page that contains this in the `_id` field
  * Event Responses
    * `read_res` - Whenever a change occurs to a page or the first read.
      * `ns` - Namespace of the fault
      * `first` - A boolean that indicates whether this page was ever received on `page_update` before. i.e. is it a change after we were already given this page previously in a `page_update` for this receiver?
      * `page` - A dictionary object that is a reference to the page. This should be treated as immutable as it is a shared resource.
  * Debug quirks
    * Sets `vm_read_sync_called` to true when called

###`create`
Creates a new page or overrides an existing one. Will automatically add timestamps to entries. If you need to modify an existing page, see [User page modification helpers](#user_page_modification_helpers)
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `id` - Watching the page that contains this in the `_id` field
    * `next` - The next pointer of the page
    * `head` - The head pointer of the page
    * `entries` - An array of dictionary entries for the array

##Helper Methods
###Pager specific
  * `vm_cache_write(ns, key, page)` - Save a page to cache memory. This will not recalculate the page hash.

###Page modification
  * `vm_rehash_page(page)` - Calculates the hash for a page and modifies that page with the new `_hash` field.

### <a name='user_page_modification_helpers'></a>User page modification helpers
You should never directly edit a page in user land; if you do; the pager has no way of knowing that you made modifications. Additionally, if you have multiple controllers watching a page, and it is modified in one controller, those other controllers
will not receive the notifications of the page modifications.

**These are only for existing pages; that is, pages that have been received through `read_res`. If you need to create a new page, do so through `create`**
####Per entry
  * `entry_del(page, eindex)` - Remove a single entry from a page.
  * `entry_insert(page, eindex, entry)` - Insert an entry, entry should be a dictionary value. It will automatically have the timestamp added.
  * `entry_dma(page, eindex)` - Returns a mutable entry at a specific index. In addition, it updates the entries `_timestamp` of the entry.

####Page attributes
  * `set_page_next(page, hash)` - Sets the `_next` hash for the page
  * `set_page_head(page, hash)` - Sets the `_head` hash for the page

##Spec helpers
The variable `vm_did_wakeup` is set to true in the wakeup part of the vm service.
