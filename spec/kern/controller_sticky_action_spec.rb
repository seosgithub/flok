#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_sticky_action_spec" do
  include_context "kern"

  it "Can use the sticky_action actions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/a.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);
    }
  end

  it "Going to an action from a sticky action does not result in the previous action releasing it's views, but it does hide them" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/a.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      _embed("foo", 0, {}, null);
    }
    foo_base = ctx.eval("foo_base")

    @driver.int "int_event", [foo_base, "next_clicked", {}]

    #Expect it not to have a free
    expect {
      @driver.ignore_up_to "if_free_view"
    }.to raise_error /Waited/

    #Should have hidden the view
    @driver.ignore_up_to "if_view_hide"
    expect(@driver.get "if_view_hide").to equal([])
  end
end
