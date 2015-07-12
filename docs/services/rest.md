#Rest Service
This is the RESTful network request service. Designed for small payloads of RESTful network requests.

#Options
  * `base_url` - The url like `"http://services.my_host.com/"` for the path to be based on. Must include ending slash.

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
will contain `path` and `res` where `path` is the `path` given in th
request and `res` is the results of the request.

###Globals
  * `rest_in_flight` - A hash that maps `rest_in_flight[tp_base] => bp` where `[bp, path]` is the requesting entity for the original request and
      `path` is the original path.
