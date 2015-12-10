#Tests to make sure the hook entry points act as the are defined in hooks.md
#and that the HookCompiler is able to correctly intercept them. Additionally,
#there are some tests here to verify the operation of the hooks compiler it's-self
#but the user-generated DSL related tests are in hook_user_generators_spec.rb

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

  it "Can use the HooksManifest & HooksManifestEntry to properly select and insert code into a hooks compatible javascript file" do
    #Since we are only looking at the HooksManifest & HooksManifestEntry, this dosen't necessarily need to be 
    #flok compatible things as only the compiler itself holds flok code. In this case, we are going to be replacing
    #some of the hook entries with code that will insert into the order array. Any problems with identifying the correct
    #hook entries will result in the order array being incorrect
    src = <<eof
//HOOK_ENTRY[first] {}
//HOOK_ENTRY[foo] {"foos": ["a", "b", "c"]}
//HOOK_ENTRY[bar] {"name": "los"}
//HOOK_ENTRY[world] {"name": "los"}
//HOOK_ENTRY[test] {"name": "los"}
//HOOK_ENTRY[test2] {"name": "los2"}
//HOOK_ENTRY[hello] {"foos": ["a"]}
//HOOK_ENTRY[foo4] {"foos": ["a", "b", "c"]}
//HOOK_ENTRY[foo6] {"world": ["a", "b", "c"], "test": ["bar"]}
//HOOK_ENTRY[foo5] {}
//HOOK_ENTRY[foo6] {"world": ["a", "b", "c"]}
eof

    #Create a new manifest which we will add all of our entries to
    manifest = Flok::HooksManifest.new

    ################################################################################
    #Now we add some manifest entries to help process the above source
    ################################################################################

    manifest << Flok::HooksManifestEntry.new("first") {|params| next "1st"} #HOOK_ENTRY[first]
    manifest << Flok::HooksManifestEntry.new("*", ->(p){p["foos"] and p["foos"].include? "b"}) {|params| next "2nd"} #'foos' containing 'b'
    manifest << Flok::HooksManifestEntry.new("*", ->(p){p["name"] == "los" }) {|params| next "3rd"} #'name' == 'los'
    manifest << Flok::HooksManifestEntry.new("test2", ->(p){p["name"] == "los2"}) {|params| next "4th"} #HOOK_ENTRY[test2] where 'name' == 'los'
    manifest << Flok::HooksManifestEntry.new("*", ->(p){p["foos"] and p["foos"].include? "a"}) {|params| next "5th"} #'foos' containing 'a'
    manifest << Flok::HooksManifestEntry.new("*", [->(p){p["world"] and p["world"].include? "a"}, ->(p){p["test"] and p["test"].include? "bar"}]) {|params| next "6th"} #'world' contains 'a' && 'test' contains 'bar'

    #Process the src line-by-line with the manifesct
    output_src = src.split("\n").map{|e| manifest.transform_line(e)}

    expect(output_src.join("\n") + "\n").to eq(<<eof
1st
2nd
5th
3rd
3rd
3rd
4th
5th
2nd
5th
6th
//HOOK_ENTRY[foo5] {}
//HOOK_ENTRY[foo6] {"world": ["a", "b", "c"]}
eof
)
  end

  it "Can use the HooksManifest & HooksManifestEntry to properly retrieve the correct set of parameters in the code block" do
    #Here we are not testing the actual selection of proper hooks, but checking that once we have a selection
    #does the code generator block get the correct static parameters? Specific parameters are tested in seperate
    #tests for each hook
    src = <<eof
//HOOK_ENTRY[foo] {"foos": ["a", "b", "c"], "hello": "world"}
eof

    #Create a new manifest which we will add all of our entries to
    manifest = Flok::HooksManifest.new

    #Now we add our manifest entry that we will check parameters on
    did_get = false
    manifest << Flok::HooksManifestEntry.new("foo") do |params| 
      did_get = true
      expect(params.to_json).to eq({"foos" => ["a", "b", "c"], "hello" => "world"}.to_json)
    end

    #Process the src line-by-line with the manifesct
    output_src = src.split("\n").map{|e| manifest.transform_line(e)}

    #Make sure we actually triggered on the entry
    expect(did_get).to eq(true)
  end

  it "Can hook the controller_will_goto event with the correct hook entry information and has the variables mentioned in the docs" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0a.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    will_gotos_found = 0
    from_to_action_pairs_found = []
    entry = Flok::HooksManifestEntry.new("controller_will_goto") do |hook_info|
      will_gotos_found += 1
      #Static parameters
      expect(hook_info["controller_name"]).to eq("my_controller")
      expect(hook_info["might_respond_to"].to_set).to eq(["foo", "hello", "test"].to_set)
      from_to_action_pairs_found << {hook_info["from_action"] => hook_info["to_action"]}

      #actions_responds_to looks like {"action1" => ["event_a", ..."], "action2" => }...
      #where each action list contains all the events this action responds to
      expect(hook_info["actions_responds_to"]).to eq({"index" => ["hello", "foo"], "other" => ["test"]})
      if hook_info["from_action"] == "other"
        expect(hook_info["handling_event_named"]).to eq("test")
      end

      #Variables included
      next %{
        entry_params = {
          old_action: old_action,
          new_action: __info__.action,
        };
      }
    end
    manifest << entry

    #Recompile source (We do this manually as we supplied no `config/hooks.rb` file)
    src = Flok::HooksCompiler.compile src, manifest
    
    #Expect to have found two will_goto entries given that there is one Goto request
    #and one implicit Goto from the entry
    expect(will_gotos_found).to eq(2)

    #Expect to have gotten all the goto to/from action pairs
    expect(from_to_action_pairs_found.to_set).to eq([{"other" => "index"}, {"choose_action" => "index"}].to_set)

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

  it "Can hook the controller_did_goto event with the correct hook entry information and has the variables mentioned in the docs" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0a.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    will_gotos_found = 0
    from_to_action_pairs_found = []
    entry = Flok::HooksManifestEntry.new("controller_did_goto") do |hook_info|
      will_gotos_found += 1
      #Static parameters
      expect(hook_info["controller_name"]).to eq("my_controller")
      expect(hook_info["might_respond_to"].to_set).to eq(["foo", "hello", "test"].to_set)
      from_to_action_pairs_found << {hook_info["from_action"] => hook_info["to_action"]}

      #actions_responds_to looks like {"action1" => ["event_a", ..."], "action2" => }...
      #where each action list contains all the events this action responds to
      expect(hook_info["actions_responds_to"]).to eq({"index" => ["hello", "foo"], "other" => ["test"]})

      if hook_info["from_action"] == "other"
        expect(hook_info["handling_event_named"]).to eq("test")
      end

      #Variables included
      next %{
        entry_params = {
          old_action: old_action,
          new_action: __info__.action,
        };
      }
    end
    manifest << entry

    #Recompile source (We do this manually as we supplied no `config/hooks.rb` file)
    src = Flok::HooksCompiler.compile src, manifest
    
    #Expect to have found two will_goto entries given that there is one Goto request
    #and one implicit Goto from the entry
    expect(will_gotos_found).to eq(2)

    #Expect to have gotten all the goto to/from action pairs
    expect(from_to_action_pairs_found.to_set).to eq([{"other" => "index"}, {"choose_action" => "index"}].to_set)

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

  it "Can hook the controller_will_push event with the correct hook entry information mentioned in the docs" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0a_push.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    will_pushs_found = 0
    from_to_action_pairs_found = []
    entry = Flok::HooksManifestEntry.new("controller_will_push") do |hook_info|
      will_pushs_found += 1
      #Static parameters
      expect(hook_info["controller_name"]).to eq("my_controller")
      expect(hook_info["might_respond_to"].to_set).to eq(["foo", "hello", "test", "holah"].to_set)
      from_to_action_pairs_found << {hook_info["from_action"] => hook_info["to_action"]}

      #actions_responds_to looks like {"action1" => ["event_a", ..."], "action2" => }...
      #where each action list contains all the events this action responds to
      expect(hook_info["actions_responds_to"]).to eq({"index" => ["hello", "foo"], "other" => ["test", "holah"]})
      expect(hook_info["handling_event_named"]).to eq("test")
    end
    manifest << entry

    #Recompile source (We do this manually as we supplied no `config/hooks.rb` file)
    src = Flok::HooksCompiler.compile src, manifest
    
    #Expect to have found one will_push entries given that there is one push request
    expect(will_pushs_found).to eq(1)

    #Expect to have gotten all the push to/from action pairs
    expect(from_to_action_pairs_found.to_set).to eq([{"other" => "index"}].to_set)

    #Re-evaluate the v8 instance
    ctx = v8_flok
    ctx.eval src

    #Now load the controller
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }
  end

  it "Can hook the controller_did_push event with the correct hook entry information mentioned in the docs" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0a_push.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    did_pushs_found = 0
    from_to_action_pairs_found = []
    entry = Flok::HooksManifestEntry.new("controller_did_push") do |hook_info|
      did_pushs_found += 1
      #Static parameters
      expect(hook_info["controller_name"]).to eq("my_controller")
      expect(hook_info["might_respond_to"].to_set).to eq(["foo", "hello", "test", "holah"].to_set)
      from_to_action_pairs_found << {hook_info["from_action"] => hook_info["to_action"]}

      #actions_responds_to looks like {"action1" => ["event_a", ..."], "action2" => }...
      #where each action list contains all the events this action responds to
      expect(hook_info["actions_responds_to"]).to eq({"index" => ["hello", "foo"], "other" => ["test", "holah"]})
    expect(hook_info["handling_event_named"]).to eq("test")
    end
    manifest << entry

    #Recompile source (We do this manually as we supplied no `config/hooks.rb` file)
    src = Flok::HooksCompiler.compile src, manifest
    
    #Expect to have found one did_push entries given that there is one push request
    expect(did_pushs_found).to eq(1)

    #Expect to have gotten all the push to/from action pairs
    expect(from_to_action_pairs_found.to_set).to eq([{"other" => "index"}].to_set)

    #Re-evaluate the v8 instance
    ctx = v8_flok
    ctx.eval src

    #Now load the controller
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }
  end

  it "Can hook the controller_will_pop event with the correct hook entry information mentioned in the docs" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0a_push.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    will_pops_found = 0
    entry = Flok::HooksManifestEntry.new("controller_will_pop") do |hook_info|
      will_pops_found += 1
      #Static parameters
      expect(hook_info["controller_name"]).to eq("my_controller")
      expect(hook_info["might_respond_to"].to_set).to eq(["foo", "hello", "test", "holah"].to_set)

      #actions_responds_to looks like {"action1" => ["event_a", ..."], "action2" => }...
      #where each action list contains all the events this action responds to
      expect(hook_info["actions_responds_to"]).to eq({"index" => ["hello", "foo"], "other" => ["test", "holah"]})
      expect(hook_info["handling_event_named"]).to eq("holah")
    end
    manifest << entry

    #Recompile source (We do this manually as we supplied no `config/hooks.rb` file)
    src = Flok::HooksCompiler.compile src, manifest
    
    #Expect to have found one will_pop entries given that there is one pop request
    expect(will_pops_found).to eq(1)

    #Re-evaluate the v8 instance
    ctx = v8_flok
    ctx.eval src

    #Now load the controller
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }
  end

  it "Can hook the controller_did_pop event with the correct hook entry information mentioned in the docs" do
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0a_push.rb')
    src = info[:src]
    ctx = info[:ctx]

    manifest = Flok::HooksManifest.new
    did_pops_found = 0
    entry = Flok::HooksManifestEntry.new("controller_did_pop") do |hook_info|
      did_pops_found += 1
      #Static parameters
      expect(hook_info["controller_name"]).to eq("my_controller")
      expect(hook_info["might_respond_to"].to_set).to eq(["foo", "hello", "test", "holah"].to_set)

      #actions_responds_to looks like {"action1" => ["event_a", ..."], "action2" => }...
      #where each action list contains all the events this action responds to
      expect(hook_info["actions_responds_to"]).to eq({"index" => ["hello", "foo"], "other" => ["test", "holah"]})
      expect(hook_info["handling_event_named"]).to eq("holah")
    end
    manifest << entry

    #Recompile source (We do this manually as we supplied no `config/hooks.rb` file)
    src = Flok::HooksCompiler.compile src, manifest
    
    #Expect to have found one did_pop entries given that there is one pop request
    expect(did_pops_found).to eq(1)

    #Re-evaluate the v8 instance
    ctx = v8_flok
    ctx.eval src

    #Now load the controller
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }
  end


end
