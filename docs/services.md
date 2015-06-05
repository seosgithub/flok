#Services
Services are helper hubs that send and receive information typically from other services or directly from interrupts. They are meant
to act as a glue between controllers and devices. Services can receive events and can run periodic events on longer intervals. They are
very similar to controllers except they do not contain actions and are meant to be used as singletons (although they are instantized, the 
instances are globally shared).

##Daemons & Agents
Services are either a `daemon` or an `agent`.  The only difference between these two is how the service is woken up (timers are allowed to run).
A `daemon`'s periodic timers are always active; even when transaction queues are cleared. An `agent` is only active if a controller or another
service holds a reference to the `agent`.

##Code
All kernel service classes are placed in `./app/kern/services/` and are ruby files. Here is an example:
```ruby
#A sample service, all services have capital letters because they are like classes and are instantized
service :sample do
  type "daemon"

  #Initialization#####################################################################################################################
  #When a service is woken_up, this function is called. A service instances is guaranteed to never be woken up
  on_wakeup %{
  }

  #When an agent service is no longer needed by a controller, AND the service has flushed all of it's transaction queues,
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
  #events to controller instances.
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

###Service function in controllers
When you are inside a controller, you may make as service request through `Request` after you declare that the controller uses a service
connection via `service :service_instance_name` where:

  * `Request(service_insatnce_name, ename, params)`
    * `service_instance_name` - The instance name of the service you are making a request from
    * `ename` - The name of the event to 'send' the service. (`on` handlers for service)
    * `params` - Any information you'd like to send along with the service.

###Example controller
```ruby
controller :controller do 
  spots "content"
  service :my_service

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
  //Create a new base pointer
  $INAME_bp = tels(1);

  //Push all events to the event handler
  reg_evt($INAME_BP, $INAME_event_handler);

  <<user code>>
}

$INAME_on_sleep() {
  <<user code>>
}

$INAME_on_connect(bp) {
  <<user code>>
}

$INAME_on_disconnect(bp) {
  <<user code>>

  //Unregister so timer events will no longer fire here
  unreg_evt($INAME_BP);
}

//For each 'on' function
$INAME_on_XXXXX(bp, params) = {
  <<user code>>
}

//For each 'every' function
$INAME_on_every_xx_sec() {
  <<user code>>
}

//Event handler
$INAME_event_handler(ep, event_name, info) {
}
```
