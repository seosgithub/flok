# Architecture
Flok's architecture is a non-pre-emptive (realtime) event-driven tickless monolithic meta-kernel divided into several parts.
```
#(a) <Platform specific drivers for handling generic/custom interrupts and generic/custom IO>
#---------^|------------------------------------
#---------||------------------------------------
#=========|v====================================          <--------------------- Abstraction barrier
#(b) <Standard driver interface> <Custom driver interfaces>                         
#---------^|------------------------------------
#---------||------------------------------------
#---------|v------------------------------------
#(c) <Generic kernel systems (ui, pipes, etc)> <Your Kernel 'tasks'>
```

* (a) - Drivers are written in any languages and must implement (b) the standard driver interface.
* (b) - All driver communication must pass directly through this layer
* (c) - This layer handles all generic activity like setting up pipes between tasks, etc.

