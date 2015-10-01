#Deep Link Service
The **deep_link** service requires the `dlink` module to function. It listens onto the `dlink` port and thus
can only be instantized once (i.e. it's a singleton service). Each controller that connects to this service
will receive the `dlink:request` event with the parameters `{url: url, params: params}`. An example of
the `url` and `params` in `http://google.com/test?foo=bar` would be `{url: "http://google.com/test", {foo: "bar"}}`

##Spec behaviours
When a request is made to the `dlink` port, see the `dlink` module for the port, any controllers registered to
this service should receive the `dlink:reqeust` with the appropriate parameters
