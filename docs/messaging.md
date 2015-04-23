#Messaging
Flok uses a message passing scheme for communication between the native device and the Flok kernel for both ways. 
Each message also has the opportunity to return

#Scheme
Each message is composed of 3 parts.

`[arg_length, function_name, *args]`
 * arg_length - How many argugments are in *args
 * function_name - What function are you calling?
 * *args - A list of arguments that are being sent to the function (any type, including hashes are supported)

Multiple messages can be coalesced by just appending them to the same (flat) array. Return values will be in an array, functions that returned nothing will have null in their array spot.

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

###Returns
Messages also have the opportunity to return something. It is recomended to try to avoid using data heavy returns and, instead, you should try to use `telepathy` protocol.

###Performance considerations
On JavaScriptCore, function calls are handled via XPC. Each call on the XPC bus is subject to scheduling noise as it has to intertwine it's execution context with the kernel's execution context. This isn't such a bad thing on *one* function call with limited amount of IPC data; if the transfer and execution happen fast enough, the kernel will defend your cpu time slice and not pre-empt you.  If there are a lot of function calls going out of your process, e.g. you make a lot of calls into the JavaScriptCore VM, then you run the risk of getting pre-empted more often. In iOS, it seems that it is **much** better to transfer more data during the XPC run then to try to call functions many times.  Failure to do so will take the typical 0.05ms function call and put +0.2ms of variance when you make a lot of calls. So moral of the story, limit transactions between the native and javascript interface and use pipelining techniques. This applies to all environments as what's good on iOS is probably going to be good on browser, etc.

### Protocols
All protocols are only allowed from the *server* side and relate to what the client is expected to respond with. These function calls are the `if_*` named function. If you have a function that requires that a protocol be followed, it should contain a comment above the function that has //@protocol1, @protocol2 or no comment if there are no protocols that it supports

##### @telepathy
All communication going across flok and the client should avoid using *real* pointers. There should be an aditional layer of dereferencing and this layer is called the telepathy layer

###### Function call contains tp_idx, tp_tags
The client should maintain a global hash table that contains the relations of tp_idx+$i -> Something that represents tp_tags[$i]

```js
//Creates a `something` object.
//@telepathy
function if_init_something(name, tp, tp_tags) {
}
```

The client should then be able to decode the telepathy pointers for any function call and when sending a message back to flak, should automatically decode telepathy pointers before dispatching them.  All driver interface functions that use telepathic pointers should describe so in their respective README. Aditionally, telepathic pointers are created on the server via `tels(n)` located in `kern/tel.js`. This function will return a number that is passed as tp_idx.  The tags are then also passed along to the function. 
