#dlink - Deep Link Service
The **deep_link** service requires the `dlink` module to function. It implements the function `dlink_notify_handler` which is called by the `dlink` 
module. All controllers that include this service will receive the `dlink_req` event with the parameters `{url: url, params: params}`. An example of
the `url` and `params` in `http://google.com/test?foo=bar` would be `{url: "http://google.com/test", {foo: "bar"}}`

##Spec behaviours
When a request is made to the `dlink` port, see the `dlink` module for the port, any controllers registered to
this service should receive the `dlink:reqeust` with the appropriate parameters
