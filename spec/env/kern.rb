require 'therubyracer'

shared_context "kern" do
  before(:each) do
    res=system('rake build:world')
    raise "Could not run build:world" unless res
    @ctx = V8::Context.new
    @ctx.load "./products/#{ENV['PLATFORM']}/application.js"

    if ENV['RUBY_PLATFORM'] =~ /darwin/
      `killall phantomjs`
      `killall rspec`
    end
  end

  #Mock a JS function, therubyracer has a bug (feature?) that it gives you the scope information
  #for the first parameter of a lambda expression called from javascript if it's in the global scope,
  #so we have to strip the scope parameter off and then splat the rest of the arguments
  def function function_name, &block
    jsb = lambda do |scope, *e|
      block.call(*e)
    end

    @ctx[function_name] = jsb
  end

  #This function allows you to replicate if_* calls on the same context as the server itself.
  #  (1) it creates a function in the server's context - This can be confusing because we're populating
  #      the server with if_* functions when they belong in the driver. 
  #
  #  (2) it creates if_dispatch, and/or updates it. This is normally exported via the driver into
  #      the JS context via native code configuring the context or, like in HTML5, a homogenous
  #      environment that supports direct calls to if_dispatch. This version of if_dispatch automatically
  #      sends calls directly to any of the functions you declared in (1) to the *same* context!
  #    
  #  Additionally, we are mocking the if_dispatch table and not *just* the function because if_* calls
  #  are *never* meant to be called directly. In order to prevent this, if_ calls are stubbed with
  #  an additional prefix __extern__ to prevent the server from using these in integration tests as
  #  they will fail in the real world in environments with non-homogenous server and client JS.
  def external_function function_name, &block
    #Prevent server code from calling local if (they must use if_dispatch!)
    function_name = "__extern__#{function_name}"

    #Mock our function in the same context
    function function_name, &block

    #Create the if_dispatch table, replaces with same if it already exists, but that's ok
    function "if_dispatch" do |q|
      q.shift #num args
      name = q.shift

      #Send a call to a function, we inject a context here because our function expects the (weird) behavior of scope
      @ctx["__extern__#{name}"].call({}, *q)
    end
  end

  #Should be used inside a external_function context, this will send a message back to `dispatch_int` which
  #would come from the driver, over some channel, and make it's way to `int_dispatch`.
  def external_int function_name, *args
    msg = [args.count, function_name, *args]
    @ctx["int_dispatch"].call(msg)
  end
end
