#Tests to make sure the hook entry points act as the are defined in hooks.md
#and that the HookCompiler is able to correctly intercept them

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require './lib/flok/hooks_compiler.rb'
require 'zlib'

RSpec.describe "kern:hook_entry_points" do
  include Zlib
  include_context "kern"

  it "Can hook the ${controller_name}_will_goto event with the correct parameters" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    manifest << Flok::HooksManifestEntry.new("my_controller_will_goto", %{
      entry_params = {
        old_action: old_action,
        new_action: __info__.action,
      };
    })
    src = Flok::HooksCompiler.compile src, manifest

    #Re-evaluate the v8 instance
    ctx = v8_flok
    ctx.eval src

    #Now load the controller
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.entry_params = entry_params;
    }

    #Verify the parametrs were set
    expect(dump["entry_params"]).not_to eq(nil)
    expect(dump["entry_params"]["old_action"]).to eq("choose_action")
    expect(dump["entry_params"]["new_action"]).to eq("index")
  end
end
