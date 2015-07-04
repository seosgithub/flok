#Virtual Memory (vm.js)
Virtual memory provides something akin to operating system virtual memory systems with an emphasis on the paging infrastructure.  Unlike an operating system, flok has the concept of a grand-unified namespaced address space that extends the concepts of caching and semantics across asynchronous and even networked systems.  This vm systems is increadibly powerful because it allows you to create custom paging devices; this allows you to use one set of semantics to perform very complicated activities like pulling a news feed or list; having that news feed cached to disk automatically; etc.

Additionally, flok introduces a notification system that works with the demand paging schemes and caching schemes that allow you to grab data *now* and then be notified whenever a fresh copy is available from the server.

Each pager belongs to a *namespace*; page faults hit a namespace and then the pager takes over. The pager can choose to service a request; or even throw an exception if a certain semantic is not supported in it's namespace; for example, you may want to disable write semantics for a network pager you called `net` because you expect people to make ordinary network requests.

Fun aside; Because of the hashing schemantics; this paging system solves the age old problem of ... how do you show that data has changed *now* when to be assured that you have perferctly synchronized data with the server?;... you need to do a 3-way handshake with the updates.  You could have a network server pager that supports writes but dosen't forward those to the network. That way, you can locally modify the page and then if the modifications were guessed correctly, the server would not even send back a page modification update! (Locally, the page would have been propogated as well).  In the meantime, after modifying the local page, you would send a real network request to the server which would in turn update it's own paging system but at that point, the server would check in with you about your pages, but miraculously, because you gussed the updated page correctly, no modifications will need to be made. You could even purposefully put a 'not_synced' key in and actually show the user when the page was correctly synchronized.

##Pages
Each page is either of a `array` type or `hash` type.

###Array type
```ruby
page_example = {
  _head: <<uuid STR or NULL>>,
  _type: "array",
  _next: <<uuid STR or NULL>,
  _id: <<uuid STR>,
  entries: [
    {_id: <<uuid STR>>, _sig: <<random_signature for inserts and modifies STR>>},
    ...
  ],
  _hash: <<CRC32 >
}
```

###Hash type
```ruby
page_example = {
  _head: <<uuid STR or NULL>>,
  _type: "hash",
  _next: <<uuid STR or NULL>,
  _id: <<uuid STR>
  entries: {
    "my_id0" => {_sig: <<random_signature for inserts and modifies STR>>},
    ...
  },
  _hash: <<CRC32 >
}
```

  * `_head (string or null)` - An optional pointer that indicates a *head* page. The head pages are special pages that contain 0 elements in the entries array, no `_head` key, and `_next` points to the *head* of the list. A head page might be used to pull down the latest news where the head will tell you whether or not there is anything left for you to receive.
  * `_next (string or null)` - The next element on this list. If `_next` is non-existant, then this page is the endpoint of the list.
  * `_id (string)` - The name of this page. Even if every key changed, the `_id` will not change. This is supposed to indicate, semantically, that this page still *means* the same thing.  For example, imagine a page.  If all entries were to be **removed** from this page and new entries were **inserted** on this page, then it would be semantically sound to say that the entries were **changed**.
  * `entries`
    * `_type == 'array'`
      * An array of dictionaries. Each element contains a `_id` that is analogous to the page `_id`. (These are not the same, but carry the same semantics).  Entries also have a `_sig` which should be a generated hash value that changes when the entry changes.
    * `_type == 'hash'`
      * A dictionary of dictionaries. Entries have a `_sig` which should be a generated hash value that changes when the entry changes.
  * `_hash (string)` - All entry `_id's`, `_next`, the page `_id`, and `head` are hashed togeather. Any changes to this page will cause this `_hash` to change which makes it a useful way to check if a page is modified and needs to be updated. The hash function is an ordered CRC32 function run in the following order.  See [Calculating Page Hash](#calculating_page_hash).

------

## <a name='calculating_page_hash'></a>Calculating Page Hash
The `_hash` value of a page is calculated in the following way:
  0. `z = 0`
  1. `z = crc32(z, _head) if _head`
  2. `z = crc32(z, _next) if _next`
  3. `z = crc32(z, _id)`
  4. `_type` dependent
    * For `_type == 'array'` 
      * `z = crc32(z, entriesN._sig)` where N goes through all entries in order.
    * For `_type == 'hash'`
      * `R = crc32(0, entries[key]._sig)` is calcuated for each entry; R is an array.
      * `z = crc32(z, r0+r1+r2+...)` where `r0, r1, ...` are the elements of the array R we just calculated. This makes order not important.

If a key is null, then the crc step is skipped for that key.  e.g. if `_head` was null, then `z = crc32(0, _head)` would be skipped

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
This is how you **read a page** and request notifications for any updates to a page. The following happens when you watch a page:
```js
if (page is resident in memory from previous cache write)
  send the caller a read_res event *now*

increment_page_ref()

//Synchronously request disk load from cache; this will block
//Even if we have a request in progress; the synchronous
//may pre-empt that event because the disk queue might be loaded;
//so we need to send this anyway
if (page is not redisent in memory and synchronous) {
  try_sync_load_from_disk_and_update_cache()
}

//Only notify if this is the first reference, other controllers who attempt a watch will not signal the pager because the pager already knows
//about this page
if first_reference {
  pager_watch()
}

//Again, only attempt this if the page is not requested by anyone else and is not synchronous (because we would have already tried). The pager will be notified in the meantime, if the disk
//comes after the pager notification; then the disk will not do anything.
if (page is not resident in memory && not_synchronous) {
  //This is an asynchronous request
  try_load_from_disk_and_update_cache()
}
```
  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `id` - Watching the page that contains this in the `_id` field
    * `sync (optional)` - If set to `true` then the cache read will be performed synchronously; however, the disk read will still be performed
        asynchronously. Additionally, all future cache reads / updates will be performed synchronously.
  * Event Responses
    * `read_res` - Whenever a change occurs to a page or the first read.
    * Returns an immutable page in params

###`unwatch`
This is how you **unwatch** a page. For view controllers that are destroyed, it is not necessary to manually `unwatch` as the `vm` service will be notified on it's disconnection and automatically remove any watched pages for it's base pointer. This should be used for thingcs like scroll lists where the view controller is no longer interested in part of a page-list.

  * Parameters
    * `ns` - The namespace of the page, e.g. 'user'
    * `id` - Unwatch the page that contains this in the `_id` field

###`write`
Creates a new page or overrides an existing one. If you are modifying an existing page, it is imperative that you do not modify the page yourself and
use the modification helpers. These modification helpers implement copy on write (COW) as well as adjust sigs on specific entries and create ids for new entries.  The proper way to do it is (a) edit the page with the modification helpers mentioned in [User page modification helpers](#user_page_modification_helpers) and (b) perform a write request. This request updates the `_hash` field. Additionally, if you are creating a page, it is suggested that you still use the modification helpers; just use the `NewPage` macro insead of `CopyPage`. Additionally, modifiying a page after making a write request is prohibited as the `vm` service may alter your page.
  * Parameters 
    * `ns` - The namespace of the page, e.g. 'user'
    * `page` - The page to write (create or update)
  * Spec helpers
    * If in `@debug` mode, the variable `vm_write_list` contains an array dictionary of the last page passed to the pager (tail is latest).

##Cache
See below with `vm_cache_write` for how to write to the cache. Each pager can choose whether or not to cache; some pagers may cache only reads while others will cache writes.  Failure to write to the cache at all will cause `watch` to never trigger. Some pagers may use a trick where writes are allowed, and go directly to the cache but nowhere else. This is to allow things like *pending* transactions where you can locally fake data until a server response is received which will both wipe the fake write and insert the new one. Cache writes will trigger `watch`; if you write to cache with `vm_cache_write` with a page that has the same `_hash` as a page that already exists in cache, no `watch` events will be triggered. Additionally, calling `vm_cache_write` with a non-modified page will result in no performance penalty. `vm_cache_write` notifies controllers asynchronously and is not effected by the `watch` flag on controllers.

###Pageout & Cache Synchronization
Cache will periodically be synchronized to disk via the `pageout` service. When flok reloads itself, and the `vm` service gets a `watch` or `watch_sync` request, the `vm` service will attempt to read from the `vm_cache` first and then read the page from disk (write that disk read to cache). The only difference between `watch_sync` and `watch` is that `watch_sync` will synchronously pull from disk and panic if there is no cache available for the page). (Both `watch` and `watch_sync` will always call the pager's after the cache read as well.)

Pageout is embodied in the function named `vm_pageout()`. This will asynchronously write `vm_dirty` to disk and clear `vm_dirty` once the write has been commited. `vm_pageout()` is called every minute by the interval timer in this service.

###Datatypes & Structures (Opaque, do not directly modify)
  * `vm_cache` - The main area for storing the cache. Stored in `vm_cache[ns][key]`. Contains all namespaces by default with blank hashes.
  * `vm_dirty` - Pages recently written to cache go on the dirty list so that they may be written when the pageout handler runs. Dictionary contains map for `vm_dirty[ns][page._id] => page` for all dirty pages. Pages are removed from the dictionary when they are written in the pageout. Contains all namespaces by default with blank hashes.
  * `vm_notify_map` - The dictionary used to lookup what controllers need to be notified about changes. Stored in `vm_notify_map[ns][id]` which yields an array of controller base pointers.
  * `vm_bp_to_nmap` - A dictionary that maps a `bp` key (usually from a controller) to a dictionary. This dictionary contains a mapping of `bp => ns => id` to an array that contains `[node, index]` where `node` is a reference to `vm_notify_map[ns][id]`. This inverted map must (a) provide a way for `unwatch` to quickly remove entries from itself and (b) provide a way for all entries in `vm_notify_map` to be removed when something (usually a controller) disconrnects.
    must support `unwatch` removal which we only receive the `bp`, `ns`, and `key`.

##Helper Methods
###Pager specific
  * `vm_cache_write(ns,  page)` - Save a page to cache memory. This will not recalculate the page hash. The page will be stored in `vm_cache[ns][id]` by.

###Page modification
  * `vm_rehash_page(page)` - Calculates the hash for a page and modifies that page with the new `_hash` field. If the `_hash` field does not exist, it
      will create it

###Functional Helpers
  * `vm_calc_diff(old_page, new_page)` - Calculate the diff between two pages.  See vm_diff section on this page

### <a name='user_page_modification_helpers'></a>User page modification helpers (Controller Macros)
You should never directly edit a page in user land; if you do; the pager has no way of knowing that you made modifications. Additionally, if you have multiple controllers watching a page, and it is modified in one controller, those other controllers
will not receive the notifications of the page modifications. Once using these modifications, you must make a request for `write`. You should not use the information you updated to update your controller right away; you should wait for a `read_res` back because you `watched` the page you just updated. This will normally be performed right away if it's something like the memory pager.

Aside, modifying a page goes against the semantics of the vm system; you're thinking of it wrong if you think that's ok. The VM system lets the pager decide what the semantics of a `write` actually means. That may mean it does not directly modify the page; maybe it sends the write request to a server which then validates the request, and then the response on the watched page that was modified will then update your controller.

If you're creating a new page, please use these macros as well; just switch out `CopyPage` for `NewPage`.

####Controller Per entry
  * `NewPage(type, id)` - Returns a new blank page; internally creates a page that has a null `_next`, `_head`, and `entries` array with 0 elements. type can either be `array` or `hash`. `_id` is generated if it is not passed.
  * `CopyPage(page)` - Copies a page and returns the new page. Internally this copies the entire page with the exception of the
      `_hash` field.
      
  * For both `array` and `hashes`, the following functions work (albeit different semantics). For array types, the `eindex` is an integer in the array, For hash types, the `eindex` is a key inside the dictionary.
    * `EntryDel(page, eindex)` - Remove a single entry from a page. (Internally this deletes the array entry).
    * `EntryInsert(page, eindex, entry)` - Insert an entry, entry should be a dictionary value. 
      * For arrays, this generates the `_sig` and `_id` for you.
      * For hashes, this generates the `_sig` for you.
    * `EntryMutable(page, eindex)` - Set a mutable entry at a specific index which you can then modify. The signature is changed for you. You can not
        use this with dot syntax like `EntryMutable(page, eindex).id = 'foo'`, you may only get a variable.
    * `SetPageNext(page, id)` - Sets the `_next` id for the page
    * `SetPageHead(page, id)` - Sets the `_head` id for the page

Here is an example of a page being modified inside a controller after a `read_res`
```js
on "read_res", %{
  //Copy page and modify it
  var page = Copy(params.page);
  
  //Remove first entry
  EntryDel(page, 0);
  
  //Insert an entry
  var my_entry = {
    z = 4;
  }
  EntryInsert(page, 0, my_entry);
  
  //Change an entry
  var e = EntryMutate(page, 1);
  e.k = 4;
  e.z = 5;
  
  //Write back page
  var info = {page: page, ns: "user"};
  Request("vm", "write", info);
}
```

##Pagers
See [Pagers](./vm/pagers.md) for information for pager responsibilities and how to implement them.

##`vm_diff` Format
vm_diff is an array of changes like a `git` changelist. The following changes are supported
  * `["entry_insert", "index", "value"]` - An entry was inserted with the given value at an index
  * `["entry_del", "index"]` - An entry was deleted with the given index

###Used by:
  * `vm_calc_diff`

##Spec helpers
The variable `vm_did_wakeup` is set to true in the wakeup part of the vm service.
