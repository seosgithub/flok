#Scheduling
**This document has incorrect information. It is a document still under development**
Flok is capable of loading 10k images simultaneously while maintaining 1ms response time on typical JS environments for UI. This is all accomplished through its scheduling system.

##History
Traditional operating systems have a *scheduler* which puts *tasks* into a *runnable* state based on the amount of *CPU* resources that task has used.  Task *fairness*, which is the amount of CPU time a task is granted, is a [heated debate](http://yarchive.net/comp/linux/fairness.html).  Our scheduler is based on the concepts of the `ULE` scheduler from [FreeBSD](freebsd.org)

##Not CPU time slices.  Resources.
The first departure from a traditional operating system scheduler is that *Flok* schedules **resources**, a super-set of **cpu time slices**.  Additionally, Flok schedules with an evented system that does not rely on a timer (as many modern OS schedulers are moving to).

##The standard Flok resources are defined with the labels:
  0. `main` - User-interface displaying, etc.
  1. `net` - Downloading, Uploading, Get requests, etc.
  2. `disk` - Transferring things to/from disk
  3. `cpu` - Tasks that tax the cpu
  4. `gpu` - Tasks that tax the gpu
  5. `async` - Tasks that shouldn't run on the main thread, but are not scheduled limited.

##Flok also has two priority classes (Does not effect `main` queue):
  * `high` - Things that need to happen soon.
  * `low` - Things that can probably wait.

Despite the similarities among these classes, there are three distinct groups of classes.  `rt` is a queue that is **never** deferred. it has the lowest latency response time and is used for UI operations. `high`, `norm`, and `low` are all **asynchronous** queues.  They are **always** deferred. `idle` is also, **always** deferred, but `idle` tasks *only* run when **nothing** else is running.

##Flok tasks
Each `task` in flok is a transaction to the native device that contains a call-back and or fixed-run-time. Each `task` belongs to *N* labels and `1` class.

##Sharing the pie
Scheduling is tricky because you can't write a scheduler that just ignores everything that isn't a *high* task if there are *high* tasks queud. That kind of scheduler will never execute other tasks, even if they are of lower importance.  Like `ULE`, `Flok` cuts the scheduling groups up into a pie so that a higher percentage of `high` tasks are given simultaneously and a low percentage of `med`, and lowest for `low` are given.

##Messages from the server
Messages sent via `if_dispatch` to the server have a special format that looks like this:
```javascript
  msg = [
    [0, 0, "ping", 1, "ping2", "hello"], => <main queue>: [0, "ping"] and [1, "ping2", "hello"]
    [1, 1, "download_image", "http://testimage.com/test.png"],
    [4, 1, "blur_button", 23]
  ]
```

The message is broken up into *3* distinct queues.  The first queue, queue 0, is the **main** queue. Each queue should be interpreted in order. That
means the *main* queue will always be synchronously executed before the rest of the queues are asynchronously dispatched. The `download_image` is
apart of the `net` queue, and the *gpu* is part of queue 4.  Look above at *Resource Labels* to see what each queue is.

## message queue count
Each time a message is sent, the queue the message to belongs to is decremented by 1.
