Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

#Any global kernel API functions go here

RSpec.describe "kern:global_function_spec" do
  include_context "kern"

  it "Can use the kern_log function which writes to kern_log_stdout" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    dump = ctx.evald %{
      kern_log("foo");
      kern_log("bar");

      dump.kern_log_stdout = kern_log_stdout;
    }

    expect(dump["kern_log_stdout"]).to eq("foo\nbar\n")
  end
end
