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
will look like one of two things, for a successful request it will look like:
```ruby
{
  path: "/original/path",
  code: 200,
  res: {
    <<response from server>>
  }
}
```

For a failed request, e.g. network connection not available, not necessarily a succesful request, the parameters will look like:
```
{
  path: "/original/path",
  code: -1,
  res: "",
}
```
> *This will be retried until the network request is succesful so be prepared to get multiple `rest_res` repsonses*


We say *not necessarily a succesful request* because even if the request goes through, if it's not
a `2XX` it may still not be succesful but that's a contract between you and your server.

###Globals
  * `rest_in_flight` - A hash that maps `rest_in_flight[tp_base] => bp` where `[bp, path]` is the requesting entity for the original request and
      `path` is the original path.
