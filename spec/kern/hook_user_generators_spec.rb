#Relating to the conversion of the user's ./config/hooks.rb file
#into the equivalent HooksManifest (This may cross-over into
#the HooksCompiler itself because we need to test side-effects)

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require './lib/flok/hooks_compiler.rb'
require 'zlib'

RSpec.describe "kern:hook_user_geenrators_spec" do
  include Zlib
  include_context "kern"

  it "Can use the :goto hook generator and receives a hook event" do
    hooks_src = %{
      hook :goto, :as => :goto do
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We should have sent out an event for the hook event
    @driver.mexpect("hook_event", ["GET", "http://localhost:8080/test", {"hello" => "world"}, Integer], 1) #network priority
  end
end
