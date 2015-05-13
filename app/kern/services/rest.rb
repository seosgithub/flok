service("rest") do
  on_init %{
    //Code inserted here is put into the global space, add initialization
    //procedures, functions that need to be called, etc.
    //
    //You may use the function respond(info) within here to 

    //Store the in-progress requests as a list of hashes
    //that contain an array in the order of [event_pointer, evenct_name]
    var service_rest_tp_to_einfo = {}

    function service_rest_callback(tp, success, info) {
      ////Lookup event info
      var einfo = service_rest_tp_to_einfo[tp];

      ////Send info back to service
      int_event(einfo[0], einfo[1], {success: success, info: info});

      //Remove entries in telepointer table and rest service info
      tel_del(tp);
      delete service_rest_tp_to_einfo[tp];
    }
  }

  on_request %{
    //Code that handles a payload goes here.
    //You have access to `info`, `ep`, and `ename` which was given in the ServiceRequest macro

    //Create a GET request that will respond to the telepointer
    var tp = tel_reg(service_rest_callback);

    //Now register the event information to respond to when a callback is received
    service_rest_tp_to_einfo[tp] = [ep, ename]

    //Start the request
    SEND("net", "if_net_req", "GET", info.url, info.params, tp)
  }
end
