#Services
Services are helper hubs that send and receive information typically from other services or directly from interrupts. They are meant
to act as a glue between controllers and devices. Services can receive events and can run periodic events on longer intervals. They are
very similar to controllers except they do not contain actions and are meant to be used as singletons (although they are instantized, the 
instances are globally shared).

##Datatypes
Services maintain the following datatypes per instance:
  * `instance_name_sessions` - A hash that contains the connection view controllers as keys and 'true' as the values.
  * `instance_name_n_sessions` - A count of the current number of active sessions

##Code
All kernel service classes are placed in `./app/kern/services/` and are ruby files. Here is an example:
```ruby
#A sample service, all services have capital letters because they are like classes and are instantized
service :sample do
  #Global space#######################################################################################################################
  #In this space, you may define functions that are accessible to anything
  global %{
    function <%= @name %>_cache_save(x) {
    };
  }
  ####################################################################################################################################

  #Initialization#####################################################################################################################
  #When a service is woken_up, this function is called. A service instances is guaranteed to never be woken up
  on_wakeup %{
  }

  #When an agent (currently all) service is no longer needed by a controller, AND the service has flushed all of it's transaction queues,
  the service will receive a sleep request. At this point, you should remove all initialized data. If your service is
  too expensive to destroy all initialized data each time it is woken and slept, then it is too expensive to wakeup at all
  and you should reconsider your design. After this function calls, this service should act like it never existed and clear
  all of it's initalized variables.
  on_sleep %{
  }
  ####################################################################################################################################

  #Session management#################################################################################################################
  #Things 'connect' to a service, which is just a function call that objects, like controllers, make to a service instance
  #that notify the service that that object is now connected. You may use this to start things like automatically sending
  #events to controller instances. You have a session list called $NAME_sessions that is an array of currently connected clients.
  on_connect %{
  }

  #When an object is destroyed, this notifies the service that that object no longer wishes to receive things from the service.
  on_disconnect %{
  }
  ####################################################################################################################################

  #Do things##########################################################################################################################
  #Services are a lot like controllers, they have a mechanism to handle events
  on :event, %{
    #Services maintain their own context variables through using <%= @name %> macros to prefix variables, each instance will have a different name
    <%= @name %>_hello = "hi";

    #Inside here you receive...
      bp - The base pointer of the 'thing' that invoked this function.
      params - The parameters that were 'sent' (i.e. called)
  }

  #Do something every 5 seconds if this service (a) has clients and (b) has nothing left in a transaction queue
  every 5.seconds %{
  }
  ####################################################################################################################################
end
```

###Variables accesible
For each service function, these are what you can access
  * `on_wakeup`
    * No variables yet
  * `on_sleep`
    * No variables left over
  * `on_connect`
    * `bp` - The base address of the controller that connected
    * `sessions` - A hash of currently active sessions where each key is a base pointer
  * `on_disconnect`
    * `bp` - The base address of the controller that disconnected
    * `sessions` - A hash of currently active sessions where each key is a base pointer
  * `every x.seconds`
    * `sessions` - A hash of currently active sessions where each key is a base pointer
  * `on`
    * `bp` - The base address of the controller that sent event
    * `params` - The parameters sent with the message
    * `sessions` - A hash of currently active sessions where each key is a base pointer

###Service function in controllers
When you are inside a controller, you may make as service request through `Request`. **You must have already declared usage of the service through
`services`**:
  * `Request(service_insatnce_name, ename, params)`
    * `service_instance_name` - The instance name of the service you are making a request from
    * `ename` - The name of the event to 'send' the service. (`on` handlers for service)
    * `params` - Any information you'd like to send along with the service.

###Example controller
```ruby
controller :controller do 
  spots "content"
  services :my_service

  action :index do
    on_entry %{
      //Request can be placed anywhere in the controller
      Request("my_service", "hello", {});
    }
  end
end
```

###Services when compiled
Services get compiled through the `services_compiler` which generates the following functions
```
$INAME_on_wakeup() {
}

$INAME_on_sleep() {
}

$INAME_on_connect(bp) {
}

$INAME_on_disconnect(bp) {
}

//For each 'on' function
$INAME_on_XXXXX(bp, params) = {
}

//Event handler
$INAME_event_handler(ep, event_name, info) {
}
```

###Services config for projects
Inside a project, `./config/services.rb` holds the services configuration. This configuration file tells flok exactly what services it should
instantize based on which class. The file contains a list of `service_instance` commands with the following format:
```ruby
service_instance :instance_name, :service_class
```

Additionally, you may pass in a hash at the end of `service_instance` that will be available as `@options` inside the service definition `rb` file.

###Spec service
By default, there is a spec service class available called 'test' when compiled with debug. This service contains a function named `$iname_function(x)` that
sets `$iname_function_args` to the input of that function.

###Roughly how the services system works
The services are all hard-coded function calls that are initialized with names like `my_instance_on_wakeup`.  You have a service *class* defined in
either the kernel `./app/kern/services` or `./app/services` in a project. These files are then used as a template when you define a service in
`./config/services.rb` in your project. The flok library `ServicesCompiler` then takes the config and services file and generates the output
javascript code to support a service.  Services are talked to through the simple function naming scheme above with the exception of timers which open
a new `evt` record every time in wakes up and stops the `evt` when it goes to sleep with a new base pointer. This means, a timer will not fire against
a service if the `evt` is no longer active. Regular `on` requests are not events because there would be way to much overhead.

The controller compiler, `UserCompiler`, mentioned in [Project](./project.md) provides the `services` method when defining a controller. This
`services` method is used in the `UserCompiler` to inject service functions directly into the controller's `ctable` definition. `_embed` and `Goto
macro` of the controllers then call `__init__` and `__dealloc__` of the `ctable` which is augmented with the necessary `services` like calling
`connect` and `disconnect`.
