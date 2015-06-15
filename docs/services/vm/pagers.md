#Virtual Memory Pagers
If you haven't already, read [VM Service](../vm.md) for context on pagers.

------
##Functions required for a pager
  * `$NAME_init(ns, options)` - Initialize your pager with a namespace (`ns`) and a set of options passed in the `service :vm` options for this pager (See [VM Service](../vm.md)) for example of options hash.
  * `$NAME_watch(id, page)` - A watch request has been placed for a page id. Multiple watch requests in the *vm service* **will not show up here**.
      You will only get one watch rquest until you receive an unwatch request. You should attempt to update the page for that key as soon as possible
      and then wait for future updates. Page is the either a cached page or `undefined`. You should never modify this directly, most pagers should use
      `_hash` to check with a server if the page needs updating at this point. Some pagers may pre-fetch more pages if there is a `_next`.
  * `$NAME_unwatch(id)` - There are no controllers that are watching the page with a page that contains this in the `_id` field
  * `$NAME_write(page)` - You should write this page, e.g. to network, and/or write to `vm_cache_write`.  Alternatively, you can write the page over the network and then let the response from that call `vm_cache_write` in what ever listening code you have.
    * `page` - A fully constructed page with correctly calculated `_hash` and _sigs on entries.


 
##When are pagers invoked?
Pagers handle all requests from controllers except for the following conditions:
  1. There is a `watch` request placed but a previous `watch` request already exists for the requested page. The pager is already aware of the page watch request and is already waiting for a response. Cached pages would have been returned to the controller that made the `watch` request.

##Where to put pagers
A new pager class can be created by adding the pager to the `./app/kern/services/pagers/*.js`. Please remember that we do not currently support multiple pager instances for each class; while there is a namespace distinction that could be used to instantize the pager; we do not support statically generating multiple copies of the global variables needed per instance.

Please name your pagers `pg_XXXX` to help make it clear that you are writing a pager.

##Built-in Pagers

####Default memory pager | `pg_mem0`
The *default memory pager* does not do anything on `watch` or `unwatch`. It depends on the cache to reply to `watch` and `watch_sync` requests created by controllers. Controllers may write to this pager via `write` which this pager will then send directly to `vm_cache_write`. This pager is always compiled into the kernel.

####Spec pager | `pg_spec0`
This pager does the following when calls are made to it's functions, it's designed to assist with `vm` kernel specs.
  * `init` - Sets `pg_spec0_init_params` to `{ns: ns, options: options}`
  * `watch` - Appends `{id: id, hash: hash}` to `pg_spec0_watchlist`
  * `unwatch` - appends id to `pg_spec0_unwatchlist`
  * `write` - Writes the given page to `vm_cache_write`

This pager only exists if the environment is in `DEBUG` mode (`@debug` is enabled).

####Mem pager | `pg_mem0`
This pager provides you with local memory that will be automatically cached to disk
  * `init` - Sets `pg_mem0_spec_did_init` to `true` if `@debug`
  * `watch` - Does nothing
  * `unwatch` - Does nothing
  * `write` - Writes the given page to `vm_cache_write`
