#Relating to the conversion of the user's ./config/hooks.rb file into the equivalent HooksManifestEntrie(s) (This may cross-over into
#the HooksCompiler itself because we need to test side-effects)

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require './lib/flok/hooks_compiler.rb'
require 'zlib'

RSpec.describe "kern:hook_pop_user_generators_spec" do
  include Zlib
  include_context "kern"

  it "Can use the :pop hook generator for all controllers (no matchers)" do
    hooks_src = %{
      hook :pop => :pop do
        #Select all
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller_0b_pop.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
      dump.on_entry_base_pointer = on_entry_base_pointer;
    }

    @driver.int "int_event", [ dump["on_entry_base_pointer"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer"], "back_clicked", {} ] 

    @driver.ignore_up_to("if_hook_event", 0)
    @driver.get "if_hook_event", 0
  end

  it "Can use the :pop hook generator for one specific controller by name" do
    hooks_src = %{
      hook :pop => :pop do
        controller "my_controller"
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller_0b_pop2.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
      dump.on_entry_base_pointer = on_entry_base_pointer;
      dump.on_entry_base_pointer2 = on_entry_base_pointer2;
    }

    @driver.int "int_event", [ dump["on_entry_base_pointer"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer2"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer"], "back_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer2"], "back_clicked", {} ] 

    @driver.ignore_up_to("if_hook_event", 0)
    @driver.get "if_hook_event", 0
    expect {@driver.ignore_up_to("if_hook_event", 0)}.to raise_error /Waited/
  end

  it "Can use the :pop hook generator for one action that responds to something (coming from thing)" do
    hooks_src = %{
      hook :pop => :pop do
        from_action_responds_to? "olah2"
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller_0b_pop2.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
      dump.on_entry_base_pointer = on_entry_base_pointer;
      dump.on_entry_base_pointer2 = on_entry_base_pointer2;
    }

    @driver.int "int_event", [ dump["on_entry_base_pointer"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer2"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer"], "back_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer2"], "back_clicked", {} ] 

    @driver.ignore_up_to("if_hook_event", 0)
    res = @driver.get "if_hook_event", 0
    expect {@driver.ignore_up_to("if_hook_event", 0)}.to raise_error /Waited/
  end

  it "can hook into a particualr action we are poping from" do
    hooks_src = %{
      hook :pop => :pop do
        from_action "other2"
      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller_0b_pop2.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
      dump.on_entry_base_pointer = on_entry_base_pointer;
      dump.on_entry_base_pointer2 = on_entry_base_pointer2;
    }

    @driver.int "int_event", [ dump["on_entry_base_pointer"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer2"], "next_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer"], "back_clicked", {} ] 
    @driver.int "int_event", [ dump["on_entry_base_pointer2"], "back_clicked", {} ] 

    @driver.ignore_up_to("if_hook_event", 0);  @driver.get "if_hook_event", 0
    expect {@driver.ignore_up_to("if_hook_event", 0)}.to raise_error /Waited/
  end

  it "Can use pop to embed a pre and post selectors which will be returned in the hooking response" do
    #Hook source code
    hooks_src = %{
      hook :pop => :pop do
        controller "my_controller"
        from_action "other"

        before_views({
          "my_controller3" => {
            "__leaf__" => "foo"
          }
        })

        after_views({
          "." => {
            "__leaf__" => "foo2"
          }
        })

      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller_0b_pop2.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
    }


    on_entry_base_pointer = ctx.eval("on_entry_base_pointer")
    on_entry_base_pointer2 = ctx.eval("on_entry_base_pointer2")

    @driver.int "int_event", [ on_entry_base_pointer, "next_clicked", {} ] 
    on_entry_base_pointer3 = ctx.eval("my_controller3_base")
    @driver.int "int_event", [ on_entry_base_pointer, "back_clicked", {} ] 

    @driver.ignore_up_to("if_hook_event", 0)
    hook_res = @driver.get "if_hook_event", 0

    expect(hook_res[1]).to eq({
      "views" => {
        "foo2" => on_entry_base_pointer2,
        "foo" => on_entry_base_pointer3
      }
    })
  end

  it "Does not dump the views until *after* the callback is received" do
    #Hook source code
    hooks_src = %{
      hook :pop => :pop do
        controller "my_controller"
        from_action "other"

        before_views({
          "my_controller3" => {
            "__leaf__" => "foo"
          }
        })

        after_views({
          "." => {
            "__leaf__" => "foo2"
          }
        })

      end
    }

    #Just expect this not to blow up
    info = flok_new_user_with_src File.read('./spec/kern/assets/hook_entry_points/controller_0b_pop2.rb'), nil, nil, hooks_src
    ctx = info[:ctx]

    #Run the embed function
    ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null); // Embed the controller
      int_dispatch([]);                                 // Dispatch any events the are pending
    }


    on_entry_base_pointer = ctx.eval("on_entry_base_pointer")
    on_entry_base_pointer2 = ctx.eval("on_entry_base_pointer2")

    @driver.int "int_event", [ on_entry_base_pointer, "next_clicked", {} ] 
    on_entry_base_pointer3 = ctx.eval("my_controller3_base")
    @driver.int "int_event", [ on_entry_base_pointer, "back_clicked", {} ] 

    #Should not have gotten a free view at this point because we popped an intercepted segue
    #So it should wait for the completion callback to release the views
    expect {@driver.ignore_up_to("if_free_view", 0)}.to raise_error /Waited/

    @driver.ignore_up_to("if_hook_event", 0)
    hook_res = @driver.get "if_hook_event", 0

    expect(hook_res[1]["views"]).to eq({
      "foo2" => on_entry_base_pointer2,
      "foo" => on_entry_base_pointer3
    })

    #This should cause the views to be dumped
    @driver.int "int_event", [hook_res[1]["cep"], "", {}]
    @driver.ignore_up_to("if_free_view", 0)
    res = @driver.get("if_free_view", 0)
    expect(res).to eq([on_entry_base_pointer3+1])
  end
end
