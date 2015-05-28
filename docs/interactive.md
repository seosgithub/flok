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
If the driver `$stdin` receives the string `RESTART\n` by itself on a single line, then it should restart itself and then next reply should be
`RESTART OK\n`
it is fully restarted. All data should be destroyed except for things explicitly synchronously flushed like the `persist` module. When this pipe is
opened, it is expected that no local data is retained; the only way to retain data is through explicit restarts. All data writes should be flushed
(fsynced) when the pipe is restarted so that no data writes are lost. Some specs expect that setting data will be fsynced when it calls restart (which
 is immediately after the set)

The test suites assume particular behavior of the pipes. Please review [./spec/env/iface.rb](../spec/env/iface.rb) for the method named `pipe_suite` for the proper behavior.

####Examples

#####Server ➜ Client
 1. **Server** calls `if_disptatch([[0, 0, 'hello']])` (**The additional 0 at the beginning is the queue, 0 in this case is the main queue**)
 2. **Server** `$stdout` *writes* `[0, 0, 'hello']\n`
 3. **Client** `$stdin` *gets* `[0, 0, 'hello']\n`
 4. **Client** calls `if_dispatch([0, 0, 'hello'])`

#####Client ➜ Server
 1. **Client** calls `int_dispatch([0, 'hello'])`
 2. **Client** `$stdout` *writes* `[0, 'hello']\n`
 3. **Server** `$stdin` *gets* `[0, 'hello']\n`
 4. **Server** calls `int_dispatch([0, 'hello'])`
