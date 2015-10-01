#Deep Link Module (dlink)
The deep linking module allows your application to support start-up URL requests. Many mobile operating systems allow apps to intercept certain URL namespaces which force redirection to an app instead of the default behaviour of a web-browser. This URL on startup feature allows the app to dynamically respond to a URL request from an outside source.

#### Kernel
`int_dlink_notify(url, params)` - An inbound deep-link was intercepted and forwarded. The params are a javascript dictionary of the link parameters and
the url is the base url of the link.  E.g. if the link was `http://google.com/test?my_param=foo` then the url would be `http://google.com/test` and the
`params` are `{my_param: foo}`. This function is owned by the sister-service `dlink` and not resident in the actual module directory.

#### Kernel Spec Interrupts
`get_int_dlink_cb_spec()` - Sends [[0, 1, "get_int_dlink_cb_spec", {url: url, params: params}]] with the last received request from `int_dlink_notify`.

#### Driver
There is no requests the driver must handle. However, the driver should dispatch the message for the `int_dlink_notify` off the main queue. It should never be dispatched
before the application has fully started up. A pause of +500ms or more is acceptable and often expected.
