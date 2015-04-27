#Scheduling
Flok is capable of loading 10k images simultaneously while maintaining 1ms response time on typical JS environments for UI. This is all accomplished through its scheduling system.

##History
Traditional operating systems have a *scheduler* which puts *tasks* into a *runnable* state based on the amount of *CPU* resources that task has used.  Task *fairness*, which is the amount of CPU time a task is granted, is a [heated debate](http://yarchive.net/comp/linux/fairness.html).  Our scheduler is based on the concepts of the `ULE` scheduler from [FreeBSD](freebsd.org)

##Not CPU time slices.  Resources.
The first departure from a traditional operating system scheduler is that *Flok* schedules **resources**, a super-set of **cpu time slices**.  Additionally, Flok schedules with an evented system that does not rely on a timer (as many modern OS schedulers are moving to).

##The standard Flok resources are defined with the labels:
  * `net` - Downloading, Uploading, Get requests, etc.
  * `disk` - Transferring things to/from disk
  * `ui` - User-interface displaying
  * `cpu` - Tasks that tax the cpu
  * `gpu` - Tasks that tax the gpu
  * `ram` - Tasks that tax the ram

##Flok also has classes:
  * `rt` - The real-time queue. Everything will execute on the current thread of execution.
  * `high` - Things that need to happen soon.
  * `norm` - Things that should happen soon.
  * `low` - Things that can probably wait.
  * `idle` - Things that can wait (or not execute if needed).

Despite the similarities among these classes, there are three distinct groups of classes.  `rt` is a queue that is **never** deferred. it has the lowest latency response time and is used for UI operations. `high`, `norm`, and `low` are all **asynchronous** queues.  They are **always** deferred. `idle` is also, **always** deferred, but `idle` tasks *only* run when **nothing** else is running.

##Flok tasks
Each `task` in flok is a transaction to the native device that contains a call-back and or fixed-run-time. Each `task` belongs to *N* labels and `1` class.

##Sharing the pie
Scheduling is tricky because you can't write a scheduler that just ignores everything that isn't a *high* task if there are *high* tasks queud. That kind of scheduler will never execute other tasks, even if they are of lower importance.  Like `ULE`, `Flok` cuts the scheduling groups up into a pie so that a higher percentage of `high` tasks are given simultaneously and a low percentage of `med`, and lowest for `low` are given.

##Tasks with a bigger mouth
What if a task consumes more `resources` of `cpu` than another task? Each task has an array `max_count` values for each label that it belongs to that decides how many copies of that task could be simultaneously dispatched usefully.  
