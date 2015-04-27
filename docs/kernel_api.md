#Kernel API

##Telepointer
`tels(n)` - Returns one number that represents the base index of the telepointer.  See [Messaging](Messaging.md) for details on telepointers.
`tel_reg(f)` - Returns a number that represents the base pointer of a function callback.
`tel_del(n)` - Delete a telepointer at some index. Does nothing if not registered with something.
`tel_reg_ptr(f, tp)` - Register an explicit telepointer address at an index. Usually for spec assistance. Do not do as a normal user, use `tel_del`
`tel_deref(i)` - Convert a tel pointer into an object. Returns the object.
`tel_exists(tp)` - Returns true or false depending on whether there is a telepointer that matches
instead.

##Networking
`get_req(owner_tp, url, params, callback)` - Request some RESTFUL get request.  The callback receives `(info)` with a data payload. Will retry until successful, will never fail. The request will be abandoned if the owner object no longer exists.

##Things that are compiled into the kernel from user given data
`MODS` - A list of modules that was specified in `./app/drivers/$PLATFORM/config.yml`
`PLATFORM` - The platform that this kernel was compiled with

#Messaging
`QUEUE(queue_index, message_name, *params)` - Queue a message to be sent out. This is a macro, careful how you type it, and it should be on one line!
