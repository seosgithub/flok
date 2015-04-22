#Supported (Driver) Interfaces
There are a number of standard interfaces. Please see [Driver Interface](driver_interface.md) for more information on what an `interface` is.

#Base interfaces (Required)
* [Event (event.js)](./event.md) - Send and receive events to arbitrary objects
* [User Interface (ui.js)](./ui.md) - Support displaying views and view hierarchies
* [Net (net.js)](./net.md) - Support asynchronous network connections
* [Timer (timer.js)](./timer.md) - A tick to keep the system up-to-date and support timeout callbacks
* [Persistance (store.js)](./store.md) - A way to store data in a key value system as well as larger blobs
* [Transitions (transition.js)](./transition.md) - Works with `ui` to provide interception of segues
