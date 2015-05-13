#Rest Service
This is the RESTful network request service. Designed for small payloads of RESTful network requests.

###Info to start a request
```js
var info = {
  url: "http://my_rest_endpoint",
  params: {
    my_param_0: "test",
  }
}
```

When you receive a request back, you will receive 
```js
{
  success: true,
  info: 
}
```
Where if success is true, then info is a hash. If success is false, then info is a failure message.
