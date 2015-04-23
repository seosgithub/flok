#Modules
Modules define an implicit contract between a client and the flok server. The contract states what messages the client will respond to, what messages the server
will respond to, and the semantics of those conversations.

Each driver lists the modules that it is able to support. The driver implementor is responsible for implementing all the messages specified in the `./doc/mod/` section.
Flok then implements it's side of the contract in the `./kern/mod/` folder. During compilation, the modules the driver supports (from the `./app/driver/$PLATFORM/config.yml`)
file is used to compile only the modules into the flok kernel that the driver supports.
