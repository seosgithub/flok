#Services
Services are helper hubs that send and receive information typically from other services or directly from interrupts. They are meant
to act as a glue between controllers and devices. Services can receive events and can run periodic events on longer intervals.

##Daemons & Agents
Services are either a `daemon` or an `agent`.  The only difference between these two is how the service is woken up (timers are allowed to run).
A `daemon`'s periodic timers are always active; even when transaction queues are cleared. An `agent` is only active if a controller or another
service holds a reference to the `agent`.

##Code
All kernel service classes are placed in `./app/kern/services/` and are ruby files. Here is an example:
```ruby
#A sample service, all services have capital letters because they are like classes and are instantized
service :Sample do
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

  #Session management#################################################################################################################
  #Services are a lot like controllers, they have a mechanism to handle function calls (not true events, these are directly called)
  on :event, %{
    #Services maintain their own context variables through using <%= @name %> macros to prefix variables, each instance will have a different name
    <%= @name %>_hello = "hi";

    #Inside here you receive...
      bp - The base pointer of the 'thing' that invoked this function.
      params - The parameters that were 'sent' (i.e. called)
  }
  ####################################################################################################################################
end
```

###Request
You initiate a service request via `Request`. This may be called only in the controller at this time. This macro takes several parameters
parameters, all of which must either be strict variable names or double quoted strings:

  * `Request(name, info, event_name)`
    * `name` - The name of the service you are making a request from
    * `info` - The information to give the service
    * `event_name` - The name of the event when a callback occurs

Callbacks are handled by redirecting them through the [event](./mod/event.md) interface `int_event`.  You should register with `reg_evt` to receive
events back from a service. The request itself is not made via the event system, only the response is.  This may seem a little odd because normally
events come in from the outside while this is an internally generated event.

###Request API
Registering a service involves adding files to the `./app/kern/services` folder. All *ruby* files in this folder are used in the compilation of 
services. You declare services in the following format. Your service should not depend on anything except particular module functions.

```
service("rest") do
  on_init %{
    #Code inserted here is put into the global space, add initialization
    #procedures, functions that need to be called, etc.
    #
    #You may use the function respond(info) within here to 

    #Store the in-progress requests as a list of hashes
    #that contain an array in the order of [event_pointer, evenct_name]
    var service_rest_tp_to_einfo = {}

    function service_rest_callback(tp, success, info) {
      //Lookup event info
      var einfo = service_rest_tp_to_einfo[tp];

      //Send info back to service
      int_event(einfo[0], einfo[1], {:success => success, :info => info});

      //Remove entries in telepointer table and rest service info
      tel_del(tp);
      delete service_rest_tp_to_einfo[tp];
    }
  }

  on_request %{
    #Code that handles a payload goes here.
    #You have access to `info`, `ep`, and `ename` which was given in the Request macro

    //Create a GET request that will respond to the telepointer
    var tp = tel_reg(service_rest_callback);

    //Now register the event information to respond to when a callback is received
    service_rest_tp_to_einfo[tp] = [ep, ename]

    //Start the request
    SEND("net", "if_net_req", "GET", info.url, info.params, tp)
  }
end
```

This is then compiled down to
```js
//***************************************
//on_init code is appended to the outside
//....
//***************************************

//Your request code is put inside a function
function service_rest_req(info, ep, ename) {
  //on_request code
}
```
