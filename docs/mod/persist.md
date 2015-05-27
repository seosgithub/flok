#Persist (persist.js)
Persistance management. Loosely based on redis.

###Driver messages
`if_per_set(ns, key, value)` - Set a key and value asynchronously.
`if_per_get(s, ns, key)` - Get a key's value, a message `int_get_res` will be sent back (asynchronously).
`if_per_get_sync(s, ns, key)` - Get a key's value, a message `int_get_res` will be sent back (synchronously).
`if_per_flush_sync()` - Blocks until all file operations are completed.
`if_per_del(ns, key)` - Delete a particular key asynchronously.
`if_per_del_ns(ns)` - Delete an entire namespace asynchronously.
`if_per_set_f(ns, key, tp)` - Tell the driver to dereference the telepointer and to save it to disk.

###Kernel interrupts
`int_get_res(s, res)` - A response retrieved from either `if_get` or `if_get_sync` that contains the session key and result dictionary.
