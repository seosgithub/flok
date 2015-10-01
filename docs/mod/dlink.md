#Deep Link Module (dlink)
Deep linking describes the protocol that many mobile devices follow where an application may intercept a target namespace of a URL and then
that application will be opened and then notified of the URL with the parameters of the link. We consider deep links to encompass the HTML5
standard as well so that everything is on an even playing field.

Therefore, this module allows you to take links to your web-application and move users to a specific page just like a real website. As a bonus,
if you have a native application, you get transparent cross-over on things like password recovery forms, targetered sign-up pages, etc. (and vice-versa
for those who have a native app and are adding a web application).

#### Kernel
`int_dlink_notify(url, params)` - An inbound deep-link was intercepted and forwarded. The params are a javascript dictionary of the link parameters and
the url is the base url of the link.  E.g. if the link was `http://google.com/test?my_param=foo` then the url would be `http://google.com/test` and the
`params` are `{my_param: foo}`. This module forwards the link notifications as an `int_event` with the event `{url: url, params: params}` to port **-33343**. There is currently one sister service called 
`deep_link` which listens for these requests.

#### Kernel Spec Behaviours
All messages sent to the `int_dlink_notify` interface will be sent to the port mentioned above in the format mentioned above.

#### Driver
There is no requests the driver must handle. However, the driver should dispatch the message for the `int_dlink_notify` off the main queue. It should never be dispatched
before the application has fully started up. A pause of +500ms or more is acceptable and often expected.
