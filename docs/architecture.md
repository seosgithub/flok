# Architecture
Flok uses a server/client architecture has one two-way communication channel that uses an extremely efficient messaging protocol.  See [Messaging](./messaging.md) for details.

The communications interface is divided up into two parts; interfaces (`if_*`) and interrupts (`int_*`).  Interfaces are going from the flok server to the client.  Interrupts are from the client to the flok server. 

![Arch](./images/flok_arch.png)
