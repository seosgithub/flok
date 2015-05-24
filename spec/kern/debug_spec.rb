Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

#The debug controller / ui spec

RSpec.describe "kern:debug_spec" do
  include_context "kern"

  #includes context, events, etc.
  it "Can retreive the controller's describe" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller_describe.rb')

    #Do not run anything
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {"hello" => "world"}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "index"}])

    #Request context for view controller
    @driver.int "int_debug_controller_describe", [base]
    @driver.mexpect("if_event", [-333, "debug_controller_describe_res", {
      "context" => {
        "hello" => "world"
      },
      "events" => [
        "test"
      ]
    }])
  end
end
