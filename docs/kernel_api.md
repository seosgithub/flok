#Kernel API

##Telepointer (Mapped I/O)
  * `tels(n)` - Returns one number that represents the base index of the telepointer.  See [Messaging](Messaging.md) for details on telepointers.
  * `tel_reg(f)` - Returns a number that represents the base pointer of a function callback.
  * `tel_del(n)` - Delete a telepointer at some index. Does nothing if not registered with something.
  * `tel_reg_ptr(f, tp)` - Register an explicit telepointer address at an index. Usually for spec assistance. Do not do as a normal user, use `tel_del`
  * `tel_deref(i)` - Convert a tel pointer into an object. Returns the object.
  * `tel_exists(tp)` - Returns true or false depending on whether there is a telepointer that matches
instead.

##CRC32
  * `crc32(seed, str)` - Will calculate a CRC32 based on a seed and a string

##Random string
  * `gen_id()` - Will return a random unique id (8 character string).

##Events
  * `reg_evt(ep, f)` - Register a function to be called when an event is processed by `int_event`. The function will receive `(ep, event_name, info)`.

  * `dereg_evt(ep)` - Do not do anything if ep is received as an `int_event`

##Networking
  * `get_req(owner_tp, url, params, callback)` - Request some RESTFUL get request.  The callback receives `(info)` with a data payload. Will retry until successful, will never fail. The request will be abandoned if the owner object no longer exists.

##Controllers
  * `_embed(vc_name, sp, context, event_gw)` - Embed a view controller in a surface-pointer. Following the rules of the ui device, embedded to a sp of
      0 is the master root view. Returns base pointer. `event_gw` is a pointer to a `vc`. If it is null, then any events coming in will not be sent to
      somewhere else if they do not match any 'on' for the current action.

##Things that are compiled into the kernel from user given data
`MODS` - A list of modules that was specified in `./app/drivers/$PLATFORM/config.yml`
`PLATFORM` - The platform that this kernel was compiled with

#Messaging
`SEND(queue_index, message_name, *params)` - Queue a message to be sent out. This is a macro, you must not put any characters beyond quotes and
variables in here.  If you need to pass a hash literal, array literal, etc, please assign the variable *before* you put it in here like
```js
var payload = {from: null, to: action};
SEND("main", "if_event", base, "action", payload);
```

##Useful global variables
