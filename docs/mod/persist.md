#Persist (persist.js)
Persistance management. Loosely based on redis. Value's can be any javascript object.

###Driver messages
`if_per_set(ns, key, value)` - Set a key and value
`if_per_get(s, ns, key)` - Get a key's value, a message `int_get_res` will be sent back, `s` is the session key that will also be sent back. If there is no key, `null` will be sent back.
`if_per_del(ns, key)` - Delete a particular key
`if_per_del_ns(ns)` - Delete an entire namespace

###TODO driver messages
`if_per_set_f(ns, key, tp)` - Tell the driver to dereference the telepointer and to save it to disk.

For race conditions, e.g, an asynchronous set is followed by a synchronous get, it is undefined as to what that behavior that will be.
I If the page does not exist, the hash value is null.t is expected that the kernel should manage the write-back cache and that the driver should not attempt a write back cache unless
it is convenient to do so.

###Kernel interrupts
`int_per_get_res(s, ns, id, res)` - A response retrieved from `if_per_get` that contains the session key and result dictionary. Currently,
the service `vm` owns this function; so session does not have an effect on the outcome; but the string `"vm"` should be used for now for any
session keys involving persist.
