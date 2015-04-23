# Testing
The best way to describe testing is by describing the commands that control testing and the procedures used to process testing for each command.

------

#####Per Driver testing
`cd ./app/drivers/$PLATFORM/; rake spec`
Each driver can optionally have a spec rake task that only operates on it's files in `./app/drivers/$PLATFORM/**/*` alone. These files should **not** test the interface as that is delegated to a different part of the testing systems which provides a generic set of tests for interfaces.

------

####Testing Driver Interface with kernel for one platform
`rake spec:iface PLATFORM=$PLATFORM`
This rake task will allow you to test one platform's interface compatability. The files run by this spec task are located in `./spec/iface/*.rb`. Additionally, this spec runs `cd ./app/drivers/$PLATFORM; rake pipe` which expects a bi-directional pipe which can be written javascript statements to and read back the responses.

------

##### Test all the spec files which tests the whole platform
`cd ./; rake spec:core`
This will execute any files in `./spec/*.rb` with the exception of files in `./spec/iface/*.rb`.

------

##### Run all tests above
`cd ./; rake spec`
This will execute:
 1. Execute `rake spec` for every platform inside the platform's `./app/drivers/$PLATFORM/` folder
 2. Execute 'rake spec:iface` at `./` for ever platform with PLATFORM=$PLATFORM
 2. Execute `rake spec:core` at `./`
