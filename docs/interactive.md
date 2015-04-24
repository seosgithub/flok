#Interactive

##Pipes
###Starting pipes
  * Client (Driver/Platform)
    * `cd ./app/drivers/$PLATFORM/; rake pipe` *or* `cd ./; rake pipe:driver PLATFORM=$PLATFORM`
  * Server
    * `cd ./; rake pipe:server PLATFORM=$PLATFORM`

###What $stdout and $stdin does for pipes

  * Server
  	- `$stdin` => `int_dispatch`
  	- `if_dispatch` => `$stdout`
  * Client
  	- `$stdin` => `if_dispatch`
  	- `int_dispatch` => `$stdout`
  
All communication *coming* from `$stdin` and *going* to `$stdout` is in un-escaped JSON formatting that follows the conventions mentioned in [Messaging](./messaging.md).

The test suites assume particular behavior of the pipes.
  * When the pipe encounters an error, that pipe is required to close it's write pipe (so that the receiver gets an eof)
  * When the pipe encounters an error, or the pipe's stdin is closed, that pipe is required to die.

####Examples

#####Server ➜ Client
 1. **Server** calls `if_dispjatch([0, 'hello'])`
 2. **Server** `$stdout` *writes* `[0, 'hello']\n`
 3. **Client** `$stdin` *gets* `[0, 'hello']\n`
 4. **Client** calls `if_dispatch([0, 'hello'])`

#####Client ➜ Server
 1. **Client** calls `int_dispatch([0, 'hello'])`
 2. **Client** `$stdout` *writes* `[0, 'hello']\n`
 3. **Server** `$stdin` *gets* `[0, 'hello']\n`
 4. **Server** calls `int_dispatch([0, 'hello'])`
