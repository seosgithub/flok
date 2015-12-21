#About
The about module returns information such as the best identifier and platform-names in a standardized way.  This is useful for things like analytics
tracking.

###Driver messages
`if_about_pull()` - A message to the driver that it should send a complaint message back to the `int_about_pull_cb` endpoint. with one parameter of a dictionary.

###Kernel messages
`int_about_pull_cb(info)` - `info` is a dictionary that contains the following values:

  * `udid` - A string that represents, to the device's best capabilities, a unique application bound identifier.
  * `platform` - A string that represents this platform, i.e. `iOS iPhone 4S 9.0`, `5.0 (Macintosh: Intem lMac...Safari)`
  * `language` - A string that represents the locale, e.g. `en-us`

###Kernel access
You may access the udid via the global functions:
  * `get_udid` - Retrieves the udid
  * `get_platform` - Retrieves the platform string
  * `get_language` - Retrieves the language
