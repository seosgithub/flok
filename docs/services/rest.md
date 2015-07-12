#Rest Service
This is the RESTful network request service. Designed for small payloads of RESTful network requests.

###Info to start a request
```js
var info = {
  path: "/user/register",
  params: {
    my_param_0: "test",
  }
}

Request("<service name>", "get", info);
```

You will then receive the event `rest_res`.

For sucessful requests, `rest_res` will be sent as an event. This event
will contain `path` and `res` where `path` is the `path` given in the 
request and `res` is the results of the request.
