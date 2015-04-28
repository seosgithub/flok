#Messaging
Flok uses two endpoints named `if_dispatch` and `int_dispatch` to communicate between the flok server and client. When the flok server wants to message the client, the flok server
calls `if_dispatch`.  When the client wants to message the flok server, the client calls `int_disptach`. These two receive virtually the same formats
with the difference being that `if_dispatch` receives a multi-array queue where each array has a number pre-pended to the front that indicates the
queue the message is supposed to be interpreted in. `int_dispatch` always run synchronously, so it does not have a multi-dimensional array, only one
array that has no integer in the front.

#Scheme
Each message is composed of 3 parts.

`[arg_length, function_name, *args]`
 * arg_length - How many argugments are in *args
 * message_name - What message type (function) is this?
 * *args - A list of arguments that are being sent to the function (any type, including hashes are supported)

Multiple messages can be coalesced by just appending them to the same (flat) array.

###Examples
Here are some simple examples

```js
//3+4
[2, "sum", 3, 4]

//sqrt(12)
[1, "sqrt", 12]

//3+4 and then sqrt(12)
[2, "sum", 3, 4, 1, "sqrt", 12]
```

### How messages are handled
On the server, all messages come through `int_dispatch`. Messages are then turned into function calls by using the
`message_name` as the function name and parameters are passed via `apply`.  All functions that are caled in this manner
live in `./app/kern/mod/` and have the convention of being called `int_*`.

On the client, the driver decides on how messages are handled. At a minimum, the client must support the `if_dispatch` function
call. The driver is given a queue suggestion based on the first number for each message queue in the `if_dispatch` call. See
[Scheduling](./scheduling.md) for more information.

### Ping
Both the client and server are responsible for being able to reply to a few test messages.

#####For the client
  - Given `[[0, 0, "ping"]]` respond with `[0, pong]`
  - Given `[[0, 1, "ping1", arg]]` respond with `[1, pong1, arg]`
  - Given `[[0, 2, "ping2", arg1, arg2]]` respond with `[1, "pong2", arg1]` and `[2, "pong2", arg1, arg2]`
  - Given `[[0, 2, "ping2", arg1, arg2]]` respond with `[1, "pong2", arg1]` and `[2, "pong2", arg1, arg2]`
  - Given `[[0, 0, "ping", 0, "ping"]]` respond with `[0, "pong"]` and `[0, "pong"]`
  - Given `[[0, 1, "ping1", secret1, 1, "ping1", secret2]]` respond with `[1, "pong1", secret1]` and `[1, "pong1", secret2]` 
  - Given `[[0, 1, "ping1", secret1, 1, "ping1", secret2]]` respond with `[1, "pong1", secret1]` and `[1, "pong1", secret2]` 
  - Given `[[0, 2, "ping2", secret1, secret2, 2, "ping2", secret2, secret1]]` respond with:
    1. `[1, "pong2", secret1]` 
    2. `[2, "pong2", secret1, secret2]` 
    3. `[1, "pong2", secret2]` 
    4. `[2, "pong2", secret2, secret1]`

#####For the server
  - Given `[0, "ping"]` respond with `[[0, 0, pong]]`
  - Given `[1, "ping1", arg]` respond with `[[0, 1, pong1, arg]]`
  - Given `[2, "ping2", arg1, arg2]]` respond with `[[0, 1, "pong2", arg1, 2, "pong2", arg1, arg2]]`
  - Given `[2, "ping2", arg1, arg2]]` respond with `[[0, 1, "pong2", arg1, 2, "pong2", arg1, arg2]]`
  - Given `[0, "ping", 0, "ping"]` respond with `[[0, 0, "pong", 0, "pong"]]`
  - Given `[1, "ping1", secret1, 1, "ping1", secret2]` respond with `[[0, 1, "pong1", secret1, 1, "pong1", secret2]]` 
  - Given `[1, "ping1", secret1, 1, "ping1", secret2]` respond with `[[0, 1, "pong1", secret1, 1, "pong1", secret2]]` 
  - Given `[2, "ping2", secret1, secret2, 2, "ping2", secret2, secret1]` respond with:
    - `[[0, 1, "pong2", secret1, 2, "pong2", secret1, secret2, 1, "pong2", secret2, 2, "pong2", secret2, secret1]]` 
  - Given `[1, "ping3", queue_name]` respond with `[[queue_index, 0, "pong3"]]`
  - Given `[1, "ping3", queue_nameA, 1, "ping3", queue_nameA, 1, "ping3", queue_nameB]` respond with `[[queue_indexA, 0, "pong3", 0, "pong3"], [queue_indexB, 0, "pong3"]]`
  - Given `[1, "ping3", queue_name]` respond with `[[queue_index, 0, "pong3"]]` and then given `[1, "ping3", queue_name]` respond with `[[queue_index, 0, "pong3"]]`

### Protocols
Protocols are informal conventions used in Flok when sending certain messages.

##### @telepathy(2)
  1. `[N+2, "if_*", ... , tp_base, tp_targets, ...]` - Multiple targets
  2. `[N+1, "if_*", ..., tp_base, ...]` - One target (acts as same above but only one target)

This protocol supports virtual de-referencing.  When an entity is initialized, the server notifies the client that it (the client) should be able to dereference that entity via the telepathic pointer (tele-pointer for short) the server
just gave in the initialization.

For most clients, this would work via having a global hash table that can relate the telepathic pointers to native pointers.
Here is an example de-reference table:
```ruby
[tp    native_addr]
 0     0x30203023
 1     0x12040212
 ```

The client receives to arguments in the message, 
  1.  `tp_base` - The *base* pointer
  2.  `tp_targets` - An array that contains the names of all the objects that need to be accessible via a tele-pointer.

An example of these arguments could be:
  1.  `tp_base` - 33
  2.  `tp_targets` - ['main_view', 'content']

These arguments are saying that the *first* pointer will be given the address `33` and needs to refer to the `main_view`.
The *second* pointer will be given the address `34`, you increment the pointer by 1 each new target. `34` will refer to the `content`
```ruby
[tp    native_addr]
 33     0x10ab4022(&mainView)
 34     0x10ab3012(&content)
 ```

On the server side, the `tp_base` comes from calling `tels(n)` where `n` is the number of targets you will need.
