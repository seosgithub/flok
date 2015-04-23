# Rakefile

##Testing related

------

#####Per Driver testing
`cd ./app/drivers/$PLATFORM/; rake spec`
Each driver can optionally have a spec rake task that only operates on it's files in `./app/drivers/$PLATFORM/**/*` alone. These fills should **not** test the interface as that is delegated to a different part of the testing systems which provides a generic set of tests for interfaces.

------

####Testing Driver Interface with kernel for one platform
`rake spec:iface PLATFORM=$PLATFORM`
This rake task will allow you to test one platform's interface compatability which includes the message dispatch functions `int_dispatch`, and `if_dispatch`,
as well as all the messaging contracts that the modules the platforms drivers supports.. The files run by this spec task are located in `./spec/iface/*.rb`.

------

##### Test all the non-interface flok kernel code and build outputs
`cd ./; rake spec:core`
This will execute any files in `./spec/*.rb` with the exception of files in `./spec/iface/*.rb`.

------

##### Run all tests above
`cd ./; rake spec`
This will execute:
 1. Execute `rake spec` for every platform inside the platform's `./app/drivers/$PLATFORM/` folder
 2. Execute 'rake spec:iface` at `./` for ever platform with PLATFORM=$PLATFORM
 2. Execute `rake spec:core` at `./`

------

##Interactive

####Open a flok server pipe for a particular platform. This will execute the flok server locally on your computer through the V8 runtime.
`rake pipe PLATFORM=CHROME`
