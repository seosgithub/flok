#Dispatching of messages
Most javascript implementations implement a sandbox where messages between the javascript core and the client is done via an access controlled xpc system. These xpc systems generally serialize 
the data to be transferred and then join the requesting processes run queue to complete the request so that the process is charged with the xpc transfer. The longer this XPC transfer takes,
the more likely the process is going to get pre-empted in the middle of the transfer and have to wait to continue the transfer until the process is rescheduled. It is in our best interest
to avoid this as it adds large amounts of latency to the application; many small transfers are preferrable to large transfers unless it is a synchronous request.  For synchronous requests,
we will be forced to block anyway, so it makes sense to allow large tranfers (but caution againts them) in synchronous requests.

In order to relieve this problem, *flok* restricts the number of pipelined messages **per queue** to 5 with the exception of the `main` queue (the only synchronous queue). That means you
can have a total of `(N*5)` messages assuming there are `N` queue types (at the time of this writing, there are 5 not including the `main` queue). It is unlikely that all queues will be used
as most requests on the flok client will not use multiple resources in one pipelined stage. The client is responsible for requesting more data until no more data is available.

##Confusion about synchronous and asynchronous
There are various stages of message processing so it can be confusing as to what is excatly synchronous and asynchronous. Flok assumes a few things
  1. The disptach mechanism, `int_dispatch`, is always called by the client synchronously, and the javascript core will always respond synchronously to `if_disptach`. 
  2. The client `if_dispatch` handler will then process the main queue on it's same synchronous thread and then dispatch, asynchronously, the remaining queues; the queues may either each dispatch messages asynchronously or synchronously w.r.t to the original queue. (out of order and parallel are supported)

Additionally, it is always ok, but not suggested, to downgrade an asynchronous request to a synchronous request.  But you can **never** downgrade a synhcronous request to an asynchronous request. Synchronous requests must be done in order and on a single thread; additionally, they can be UI requests which are typically handled on the main thread.

For example, if we dispatch on the `main` queue a disk read request, flok would expect that the disk read would block the javascript core and return execution as soon as the disk read completed. Flok would also presume that the disk read was done at the fastest
and highest priority of IO and CPU.

Flok would expect that same disk requets, dispatched on an asynhcronous queue, like `disk`, that the request would not execute on the same thread of execution and could execute out of order.

##The standard Flok queues (resources) are defined with the labels:
  0. `main` - User-interface displaying, etc.
  1. `net` - Downloading, Uploading, Get requests, etc.
  2. `disk` - Transferring things to/from disk
  3. `cpu` - Tasks that tax the cpu
  4. `gpu` - Tasks that tax the gpu

##Messages from the server
Messages sent via `if_dispatch` to the server have a special format that looks like this:
```javascript
  msg = [
    [0, 0, "ping", 1, "ping2", "hello"],
    [1, 1, "download_image", "http://testimage.com/test.png"],
    [4, 1, "blur_button", 23]
  ]
```

The message is broken up into *3* distinct queues.  The first queue, queue 0, is the **main** queue. Each queue should be interpreted in order. That
means the *main* queue will always be synchronously executed before the rest of the queues are asynchronously dispatched. The `download_image` is
apart of the `net` queue, and the *gpu* is part of queue 4.  Look above at *Resource Labels* to see what each queue is.

##Example of a session where the flok server does not respond with all messages right away to a client
Imagine that a flok server has the following available in it's queues for transfer in int_dispatch
```javascript
    main_q = [[0, "ping", [0, "ping"], [0, "ping"], [0, "ping"], [0, "ping"], [0, "ping"],
    net_q = [[1, "download", "..."], [1, "download", "..."], [1, "download", "..."], [1, "download", "..."], [1, "download", "..."], [1, "download", ...]  ,
    gpu_q = [[1, "blur_button", 23]]
```
The `main_q` contains over 5 messages. However, because the `main_q` is dispatched synchronously, we will send those all at once. The `net_q` has
6 messages; so we will only send 5 of those at once. The `gpu_q` only contains 1 message, so we will send that at once.

The client then calls `int_dispatch`:
```javascript
  res = int_disptach(...)
```

And it receives this in `res`:
```javascript
  'i',
  [0, 0, "ping", 0, "ping", 0, "ping", 0, "ping", 0, "ping", 0, "ping"],
  [1, 1, "download", "..."], 1, "download", "...", 1, "download", "...", 1, "download", "...", 1, "download", "..."]
  [4, 1, "blur_button", 23]
```

Notice how it's the same as the int_dispatch from the server except that queue 1 (`net_q`) is missing 1 message ([1, "download", "..."]). The 'i' at the start
indicates that the request is 'incomplete' and the client should request with a blank request array following completion of dequing all these events. The second request should be **asynchronous** w.r.t to the frist request and the third request asynchronous w.r.t to the second request. This is because, if there were enough events, the main thread would be blocked until the full queue was finished de-queing. This raises an issue; what happends if a request comes through before the asynchronous request comes through? Nothing special. Clients should prioritize the request queue to dispatch things that need `int_event` *now* instead of wait until the queue is drained. While the requests will do the same thing either which way; you don't want to pre-empt the higher priority request while it's waiting for a low priority queue drain else you lose the benefits.
So the flok server still has the following in it's queues. The `net_q` will be transfered after the next client request which will take place
after the `int_dispatch` call as the client should always call `int_dispatch` as many times until it gets a blank que `int_dispatch` as many times until it gets a blank queue.

Additionally, the `i` flag can be used with no information initially given. This arises when the `event` module en-queues an incomplete request because the `event` module needs to support defering the next event call.


**Again, we can not stress how important it is to ensure that incompletion de-queueing is asynchronous. Behaviorally, your program will be the same; but it has a much larger opportunity to cause latency as the de-queing itself (and remmeber, requests that request incompleteness but are not incomplete themselves are **still** synchronous**

Note that:
While at first you might think we need to test that int_dispatch called intra-respond of our if_event needs to test whether or not we still send
out blank [] to int_dispatch; this is not the case. In the real world, flok is supposed to also make any necessary if_disptach calls during all
int_dispatch calls. We would always receive back if_dispatch; and thus it would follow the same rules as layed out here

```javascript
    main_q = [0]
    net_q = [1, 1, "download", ...]
    gpu_q = [4]
```

##Spec helpers

###Kernel
The kernel has the function in `@debug`
  * `spec_dispatch_q(queue, count)` - Which will internally queue the message [0, "spec"] to the queue given in `queue` `count` times

###Driver 
`dispatch_spec` to assist with testing of the 'i' re-request behavior.
