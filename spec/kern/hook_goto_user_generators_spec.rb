#Relating to the conversion of the user's ./config/hooks.rb file into the equivalent HooksManifestEntrie(s) (This may cross-over into
#the HooksCompiler itself because we need to test side-effects)

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require './lib/flok/hooks_compiler.rb'
require 'zlib'

RSpec.describe "kern:hook_goto_user_generators_spec" do
  include Zlib
  include_context "kern"

  it "Can use the :goto hook generator for all controllers (no matchers)" do
    hooks_src = %{
      hook :goto => :goto do
        #Select all
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
    }

    #We should have sent out an event for the hook event twice as we have two controllers
    @driver.ignore_up_to("if_hook_event", 0)
    @driver.get "if_hook_event", 0
    @driver.ignore_up_to("if_hook_event", 0)
  end

  it "Can use the :goto hook generator for a specific controller (by name) and receives a hook event" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        controller "my_controller"
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
    }

    @driver.ignore_up_to("if_hook_event", 0); @driver.get "if_hook_event", 0 #We should have sent out an event for the hook event
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)  # At this point, we should have not received any events for if_hook_event, as we are not selecting the embedded controller
  end

  it "Can use the :goto hook generator for a controller with the triggered_by constraint for various actions" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        triggered_by "back_clicked"
      end
    }

    #Get a new js context with the controllers source and the hooks source
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    File.write File.expand_path("~/Downloads/src.txt"), info[:src]
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);         // Embed the controller
      int_dispatch([]);                                         // Dispatch any events the are pending
      dump.my_other_controller_base = my_other_controller_base; // Grab the base address of 'my_other_controller'
    }

    @driver.int "int_event", [ dump["my_other_controller_base"], "back_clicked", {} ] 
    @driver.ignore_up_to("if_hook_event", 0)
  end


  it "Can use the :goto hook generator for a controller with the to_action_responds_to constraint for various actions" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        to_action_responds_to? "back_clicked"
      end
    }

    #Get a new js context with the controllers source and the hooks source
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    File.write File.expand_path("~/Downloads/src.txt"), info[:src]
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);         // Embed the controller
      int_dispatch([]);                                         // Dispatch any events the are pending
      dump.my_other_controller_base = my_other_controller_base; // Grab the base address of 'my_other_controller'
    }

    #The index of my_other_controller contains the back_clicked event, 
    #and since this is embedded in the my_controller's index, this should have created an event
    @driver.ignore_up_to("if_hook_event", 0)
    event = @driver.get "if_hook_event", 0

    #Now we switch to an action that dosen't contain a back_clicked event for my_other_controller, so it shouldn't have triggered any hook event
    @driver.int "int_event", [ dump["my_other_controller_base"], "back_clicked", {} ] 
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)

    #Now we switch to the 3rd action which still contains no back_clicked
    @driver.int "int_event", [ dump["my_other_controller_base"], "next_clicked", {} ]
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)

    #Now we switch to the 4th action which *does* contains a back_clicked
    @driver.int "int_event", [ dump["my_other_controller_base"], "next_clicked", {} ]
    expect { @driver.ignore_up_to("if_hook_event", 0); @driver.get "if_hook_event", 0 }.not_to raise_error
  end

  it "Can use the :goto hook generator for a controller with the from_action_responds_to constraint for various actions" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        from_action_responds_to? "back_clicked"
      end
    }

    #Get a new js context with the controllers source and the hooks source
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    File.write File.expand_path("~/Downloads/src.txt"), info[:src]
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);         // Embed the controller
      int_dispatch([]);                                         // Dispatch any events the are pending
      dump.my_other_controller_base = my_other_controller_base; // Grab the base address of 'my_other_controller'
    }

    #Although the first action has a 'back_clicked', it is going to it so this shouldn't have raised an event
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)

    #Now we switch to an action and our last action contained a back click
    @driver.int "int_event", [ dump["my_other_controller_base"], "back_clicked", {} ] 
    expect { @driver.ignore_up_to("if_hook_event", 0); @driver.get "if_hook_event", 0 }.not_to raise_error

    #Now we switch to the 3rd action and the last action didn't contain a back clicke
    @driver.int "int_event", [ dump["my_other_controller_base"], "next_clicked", {} ]
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)

    #Now we switch to the 4th action and the last action did not contain a back click
    @driver.int "int_event", [ dump["my_other_controller_base"], "next_clicked", {} ]
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)

    #Now we switch to the 2nd action and the last action had a back clicked
    @driver.int "int_event", [ dump["my_other_controller_base"], "back_clicked", {} ]
    expect { @driver.ignore_up_to("if_hook_event", 0); @driver.get "if_hook_event", 0 }.not_to raise_error
  end

  it "Can use the :goto hook generator for a controller with the to_action constraint for various actions" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        to_action "other"
      end
    }

    #Get a new js context with the controllers source and the hooks source
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0b.rb'), nil, nil, hooks_src
    File.write File.expand_path("~/Downloads/src.txt"), info[:src]
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);         // Embed the controller
      int_dispatch([]);                                         // Dispatch any events the are pending
      dump.my_controller_base = my_controller_base;
    }

    #Should raise a hook at this time
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)
    @driver.int "int_event", [ dump["my_controller_base"], "next_clicked", {} ] 
    expect { @driver.ignore_up_to("if_hook_event", 0); @driver.get "if_hook_event", 0 }.not_to raise_error
  end

  it "Can use the :goto hook generator for a controller with the from_action constraint for various actions" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        from_action "index"
      end
    }

    #Get a new js context with the controllers source and the hooks source
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0b.rb'), nil, nil, hooks_src
    File.write File.expand_path("~/Downloads/src.txt"), info[:src]
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);         // Embed the controller
      int_dispatch([]);                                         // Dispatch any events the are pending
      dump.my_controller_base = my_controller_base;
    }

    #Should raise a hook at this time
    expect { @driver.ignore_up_to("if_hook_event", 0) }.to raise_error(/Waited for/)
    @driver.int "int_event", [ dump["my_controller_base"], "next_clicked", {} ] 
    expect { @driver.ignore_up_to("if_hook_event", 0); @driver.get "if_hook_event", 0 }.not_to raise_error
  end

  it "Can use goto to embed a pre and post selectors which will be returned in the hooking response" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        controller "my_controller"
        to_action_responds_to? "test"

        before_views({
          "." => {
            "__leaf__" => "foo"
          }
        })

        after_views({
          "new_controller" => {
            "__leaf__" => "foo2"
          }
        })

      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
    }


    my_other_controller_base = ctx.eval("my_other_controller_base")
    on_entry_base_pointer = ctx.eval("on_entry_base_pointer")

    #Now we switch to an action and our last action contained a back click
    @driver.int "int_event", [ on_entry_base_pointer, "hello", {} ] 
    new_controller_base = ctx.eval("new_controller_base")

    @driver.ignore_up_to("if_hook_event", 0)
    hook_res = @driver.get "if_hook_event", 0

    expect(hook_res[1]["views"]).to eq({
      "foo" => my_other_controller_base,
      "foo2" => new_controller_base
    }
    )
  end

  it "The goto does not free views via the module until after the completion event is received" do
    #Hook source code
    hooks_src = %{
      hook :goto => :goto do
        controller "my_controller"
        to_action_responds_to? "test"
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller0.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
    }


    my_other_controller_base = ctx.eval("my_other_controller_base")
    on_entry_base_pointer = ctx.eval("on_entry_base_pointer")

    #Now we switch to an action and our last action contained a back click
    @driver.int "int_event", [ on_entry_base_pointer, "hello", {} ] 
    new_controller_base = ctx.eval("new_controller_base")

    #Should not receive a free view here because we have not sent the completion handler back
    expect {
      @driver.ignore_up_to("if_free_view", 0)
    }.to raise_error /Waited/

    @driver.ignore_up_to("if_hook_event", 0)
    hook_res = @driver.get "if_hook_event", 0

    #We need to have a 'completion' tele-pointer to signal back
    cep = hook_res[1]["cep"]
    expect(cep).not_to eq(nil)

    #Now we send the completion event
    @driver.int "int_event", [cep, "", {}]

    #Now we should have received our free views
    @driver.ignore_up_to("if_free_view", 0)
    free_view = @driver.get "if_free_view", 0
    expect(free_view).to eq([
      my_other_controller_base+1
    ])
  end
end
