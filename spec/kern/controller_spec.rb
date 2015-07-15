#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_spec" do
  include_context "kern"

  #Can initialize a controller via embed and have the correct if_dispatch messages
  it "Can initiate a controller via _embed" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
  end

 #Can initialize a controller via embed and that controller has the correct info
  it "Can initiate a controller via _embed" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {secret: "#{secret}"}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {"secret" => secret}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
  end

  it "Does raise a sensible error if a controller does not exist" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    did_error = false
    #Run the embed function
    begin
      secret = SecureRandom.hex
      ctx.eval %{
        //Call embed on main root view, should fail
        base = _embed("my_non_existant_controller", 0, {secret: "#{secret}"}, null);
      }
    rescue V8::Error => e
      expect(e.message).to include("my_non_existant_controller")
      did_error = true
    end

    expect(did_error).to eq(true)
  end

  #Can initialize a controller via embed and the sub-controller has the correct info
  it "Can initiate a controller via _embed" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/embed_info.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {secret: "#{secret}"}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {"secret" => secret}])
    @driver.mexpect("if_attach_view", [base+1, 0])

    #We expect the sub controller to receive the same info
    @driver.mexpect("if_init_view", ["my_sub_controller", {}, base+5, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base+4, base+5, "my_sub_controller", {"secret" => secret}])
  end

  it "Can initiate a controller via _embed and have a controller_info located in tel table" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    ctx.eval %{ 
      info = tel_deref(#{base})
    }

    info = ctx.eval("info")
    expect(info).not_to eq(nil)

    #Should have the right set of keys in the controller info
    ctx.eval %{
      context = info.context
      action = info.action
      cte = info.cte
      event_gw = info.event_gw
    }

    expect(ctx.eval('context')).not_to eq(nil)
    expect(ctx.eval('action')).not_to eq(nil)
    expect(ctx.eval('cte')).not_to eq(nil)
    expect(ctx.eval('"event_gw" in info')).not_to eq(nil)
  end

 it "calls on_entry with the base pointer when a controller is embedded for the initial action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base"))
  end

  it "calls on_entry with the base pointer when a controller is embedded for the initial action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base"))
  end

  it "can embed a controller within a controller and put the right views in" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval('base')

    #First, we expect the base vc to be setup as a view
    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0])

    #Now we expect the embedded view to be setup as a view within the base view
    #It's +5, because the base takes us 4 (+3) entries, and then the next embedded takes up
    #the next view controlelr and finally main view entry (5th)
    @driver.mexpect("if_init_view", ["my_sub_controller", {}, base+5, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base+4, base+5, "my_sub_controller", {}])
    @driver.mexpect("if_attach_view", [base+5, base+2])

    #Now expect actions in reverse order up hierarchy
    @driver.mexpect("if_event", [base+4, "action", {"from" => nil, "to" => "my_action"}])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
  end

  it "can embed a controller within a controller and allocate the correct view controller instance" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view, this controller also embeds a controller
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval('base')

    #+4 because it's after the parent vc's ['vc', 'main', 'hello', world'] ['vc', 'main', 'hello']
    #                                                                        ^^
    ctx.eval %{ 
      info = tel_deref(#{base+4})
    }

    info = ctx.eval("info")
    expect(info).not_to eq(nil)
  end

  it "calls on_entry with the base pointer when the sub_controller is embedded" do
    #compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    #run the embed function
    ctx.eval %{
      //call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //drain queue
      int_dispatch([]);
    }

    #+4 because the base has 2 spots, so it should have incremented to 4
    expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base")+4)
  end

  it "Can receive 'test_event' destined for the controller and set a variable" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/test_event.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with test event
      int_dispatch([3, "int_event", base, "test_event", {}]);
    }

    #Now we expect some variables to be set in the action
    expect(ctx.eval("test_action_called_base")).not_to eq(nil)
    expect(ctx.eval("test_action_called_params")).not_to eq(nil)
  end

  it  "Can initiate a controller via _embed and have a tracked list of embeds in info" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    ctx.eval %{ 
      info = tel_deref(#{base})
    }

    #Should have the right set of keys in the controller info
    ctx.eval %{
      embeds = JSON.stringify(info.embeds)
    }
    embeds = JSON.parse(ctx.eval("embeds"))

    #Expect base+4 because it's the vc itself, not the spot it's in
    expect(embeds).to eq([[base+4], []])
  end

  it "Can receive 'test_event' and change actions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/goto.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with test event
      int_dispatch([3, "int_event", base, "test_event", {}]);
    }

    #Now we expect the action for the controller to be 'my_other_action' and for it's on_entry
    #to be called
    expect(ctx.eval("my_other_action_on_entry_called")).not_to eq(nil)
  end

  it "Does tear down the old embedded view from the embedded view controller when switching actions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/goto.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with test event
      int_dispatch([3, "int_event", base, "test_event", {}]);
    }

    base = ctx.eval("base")

    #Expect that a view was embedded inside a view at this point
    #The view (or main spot/view) should be base+1 because base+0 is the vc itself.
    #['vc', 'main', 'hello', 'world'], ['vc', 'main']
    #|--0-----1--------2--------3---|=======================The my_controller
    #                                  |-4------5---|====== The my_controller2
    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0]) #Attach to main root spot

    #Embed my_controller2 in action 'my_action'
    @driver.mexpect("if_init_view", ["my_controller2", {}, base+5, ["main"]])
    @driver.mexpect("if_controller_init", [base+4, base+5, "my_controller2", {}])
    @driver.mexpect("if_attach_view", [base+5, base+2])

    #Expect action start
    @driver.mexpect("if_event", [base+4, "action", {"from" => nil, "to" => "my_action"}])

    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])

    #And then the request to switch views with the 'test_event' removed the second view
    @driver.mexpect("if_free_view", [base+5])
  end

  it "Can receive 'test_event' in a child view and set a variable in the parent view (bubble up)" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/test_event2.rb')

    #Run the embed function
    #['vc', 'main', 'content'] ['vc', 'main']
    #  0      1         2        3       4
    #  Send message to base+3
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with test event
      int_dispatch([3, "int_event", base+3, "test_event", {}]);
    }

    #Now we expect some variables to be set in the action
    expect(ctx.eval("test_action_called_base")).not_to eq(nil)
    expect(ctx.eval("test_action_called_params")).not_to eq(nil)
  end

  it "Can receive 'test_event' in a child view and not crash when bubble up" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/test_event3.rb')

    #Run the embed function
    #['vc', 'main', 'content'] ['vc', 'main']
    #  0      1         2        3       4
    #  Send message to base+3
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with test event
      int_dispatch([3, "int_event", base+3, "test_event", {}]);
    }
  end

  it "When it changes actions, it sends an event to the controller called 'action'" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/goto2.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with test event
      int_dispatch([3, "int_event", base, "test_event", {}]);
    }

    base = ctx.eval("base")

    #The usual
    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
    @driver.mexpect("if_event", [base, "action", {"from" => "my_action", "to" => "my_other_action"}])
  end

  #It can instate a controller that uses a def in the controller inside an action to define an event handler
  it "Can initiate a controller via _embed and def a macro that can be used inside the action to define an event" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller_def.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //Drain queue with test event
      int_dispatch([3, "int_event", base, "test_event", {}]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "content"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
    @driver.mexpect("if_event", [base, "action", {"from" => "my_action", "to" => "my_other_action"}])
  end

  #Can send a custom event from the flok controller
  it "Can send a custom event from the flok controller via Send" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/send_event.rb')

    secret = SecureRandom.hex

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue with an event
      int_dispatch([3, "int_event", base, "hello", {secret: "#{secret}"}]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
    @driver.mexpect("if_event", [base, "test_event", {"secret" => secret}])
  end

  it "makes the child's event_gw the parent controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/event_gw.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {secret: "#{secret}"}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    sub_event_gw = ctx.eval("sub_event_gw")

    expect(sub_event_gw).to eq(base)
  end


  #Can have a sub-controller Raise an event and for the parent controller to receive this
  it "Can have a sub-controller Raise an event and for the parent controller to receive this" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/raise_event.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {secret: "#{secret}"}, null);

      //Drain queue
      int_dispatch([]);
    }

    #This is set when the parent controller receives an event
    raise_res_context = JSON.parse(ctx.eval("JSON.stringify(raise_res_context)"))

    expect(raise_res_context).to eq({"secret" => "#{secret}", "hello" => "world"})
  end

  #Can signal a spot from a parent controller
  it "Can signal a spot sub-controller and trigger an event" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/lower_event.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "test_event", {secret: "#{secret}"}]);
    }

    #This is set when the parent controller receives an event
    lower_request_called_with = JSON.parse(ctx.eval("JSON.stringify(lower_request_called_with)"))

    expect(lower_request_called_with).to eq({"secret" => "#{secret}"})
  end

  it "Does run the global on_entry function when it is present upon entering the first action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/global_on_entry.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    expect(ctx.eval("global_on_entry_called")).to eq(true)
  end

  it "Does run the global on_entry function only on the first action and not subsequent actions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/global_on_entry2.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      global_on_entry_called_count = 0;

      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "test", {}]);
    }

    expect(ctx.eval("global_on_entry_called_count")).to eq(1)
  end

  it "Does allow macros in the global on_entry function" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/global_on_entry3.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      global_on_entry_called_count = 0;

      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "test", {}]);
    }

    base = ctx.eval("base")
    expect(ctx.eval("global_on_entry_called_count")).to eq(1)
    @driver.ignore_up_to "if_event"
    @driver.mexpect("if_event", [base, "test", {}])
  end

  it "Does allow context in the global on_entry function" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/global_on_entry4.rb')

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      global_on_entry_called_count = 0;

      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      int_dispatch([]);
    }

    base = ctx.eval("base")
    @driver.ignore_up_to "if_event"
    @driver.mexpect("if_event", [base, "context", {"base" => base, "secret" => "foo"}])
  end

  it "Does allow service macros in the global on_entry function" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/global_on_entry5.rb'), File.read("./spec/kern/assets/vm/config5.rb") 

    #Run the embed function
    secret = SecureRandom.hex
    ctx.eval %{
      global_on_entry_called_count = 0;

      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      int_dispatch([]);
    }

    expect(ctx.eval("read_res_called")).to eq(true)
  end

  it "Does allow interval (every) events" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/interval.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);
    }

    base = ctx.eval("base")

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(1)
    expect(ctx.eval("every_05_called_count")).to eq(0)
    expect(ctx.eval("every_1_called_count")).to eq(0)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(2)
    expect(ctx.eval("every_05_called_count")).to eq(1)
    expect(ctx.eval("every_1_called_count")).to eq(0)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(3)
    expect(ctx.eval("every_05_called_count")).to eq(1)
    expect(ctx.eval("every_1_called_count")).to eq(0)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(4)
    expect(ctx.eval("every_05_called_count")).to eq(2)
    expect(ctx.eval("every_1_called_count")).to eq(1)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(5)
    expect(ctx.eval("every_05_called_count")).to eq(2)
    expect(ctx.eval("every_1_called_count")).to eq(1)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(6)
    expect(ctx.eval("every_05_called_count")).to eq(3)
    expect(ctx.eval("every_1_called_count")).to eq(1)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(7)
    expect(ctx.eval("every_05_called_count")).to eq(3)
    expect(ctx.eval("every_1_called_count")).to eq(1)

    @driver.int "int_timer"
    expect(ctx.eval("every_025_called_count")).to eq(8)
    expect(ctx.eval("every_05_called_count")).to eq(4)
    expect(ctx.eval("every_1_called_count")).to eq(2)

    #Ignore up to, block must pass as well; if_event would otherwise include action
    @driver.ignore_up_to("if_event", 0) do |args|
      args[1] == "025_message"
    end

    #Now we expect our if_event messages
    8.times do
      @driver.ignore_up_to("if_event")
      @driver.mexpect "if_event", [base, "025_message", {}]
    end
  end

  #See 0000 docs/known_problems.md
  #it "Does not call intervals of other actions; and still works when switching back actions" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/interval2.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);
    #}

    #base = ctx.eval("base")

    ##In first action, only 025 is enabled
    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(1)
    #expect(ctx.eval("every_05_called_count")).to eq(0)
    #expect(ctx.eval("every_1_called_count")).to eq(0)

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(2)
    #expect(ctx.eval("every_05_called_count")).to eq(0)
    #expect(ctx.eval("every_1_called_count")).to eq(0)

    ##Switch actions, only 05 and 01 are enabled
    #ctx.eval %{ int_dispatch([base, "int_event", base, "next", {}]); }

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(2)
    #expect(ctx.eval("every_05_called_count")).to eq(0)
    #expect(ctx.eval("every_1_called_count")).to eq(0)

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(2)
    #expect(ctx.eval("every_05_called_count")).to eq(1)
    #expect(ctx.eval("every_1_called_count")).to eq(0)

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(2)
    #expect(ctx.eval("every_05_called_count")).to eq(1)
    #expect(ctx.eval("every_1_called_count")).to eq(0)

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(2)
    #expect(ctx.eval("every_05_called_count")).to eq(2)
    #expect(ctx.eval("every_1_called_count")).to eq(1)

    ##Now switch back to first action again, only 025 is enabled
    #ctx.eval %{ int_dispatch([base, "int_event", base, "back", {}]); }

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(3)
    #expect(ctx.eval("every_05_called_count")).to eq(2)
    #expect(ctx.eval("every_1_called_count")).to eq(1)

    #@driver.int "int_timer"
    #expect(ctx.eval("every_025_called_count")).to eq(4)
    #expect(ctx.eval("every_05_called_count")).to eq(2)
    #expect(ctx.eval("every_1_called_count")).to eq(1)
  #end

  it "Does not fire interval after leaving a controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/interval3.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);
    }

    base = ctx.eval("base")

    @driver.int "int_timer"
    expect(ctx.eval("timer_called")).to eq(1)
    @driver.int "int_timer"
    expect(ctx.eval("timer_called")).to eq(2)

    #Switch controllers via Goto
    ctx.eval %{ int_dispatch([base, "int_event", base, "next", {}]); }

    #Now we expect our if_event messages
    4.times do
      @driver.int "int_timer"
    end

    expect(ctx.eval("timer_called")).to eq(2)
  end

  it "Does support the optional choose_action function" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/choose_action.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);
    }
  end

  it "Does support the optional choose_action function with on_entry, and on_entry is called after on_entry global and before the first actions on_entry" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/choose_action.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);
      dump.on_entry_call_order = on_entry_call_order; 

      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }
    }

    #Global on_entry should be called before choose_action_on_entry
    expect(dump["on_entry_call_order"]).to eq([
      "global_on_entry",
      "choose_action_on_entry",
      "index_on_entry"
    ])

    #Expect not to get an event from the choose_action
    @driver.ignore_up_to "if_event"
    @driver.mexpect("if_event", [Integer, "action", {"from" => nil, "to" => "index"}])
  end

  it "Does support a controller that lacks choose_action, the first action will be the first action that appears in the controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/no_choose_action.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);
      dump.on_entry_call_order = on_entry_call_order; 

      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }
    }

    #Global on_entry should be called before choose_action_on_entry
    expect(dump["on_entry_call_order"]).to eq([
      "global_on_entry",
      "index_on_entry"
    ])

    #Expect not to get an event from the choose_action
    @driver.ignore_up_to "if_event"
    @driver.mexpect("if_event", [Integer, "action", {"from" => nil, "to" => "index"}])
  end

  it "Does support using a synchronous request in choose_action" do
    ctx = flok_new_user File.read('./spec/kern/assets/choose_action_sync.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Expect not to get an event from the choose_action
    @driver.ignore_up_to "if_event"
    @driver.mexpect("if_event", [Integer, "action", {"from" => nil, "to" => "index"}])
  end

  it "Not setting a Goto will result in an exception" do
    ctx = flok_new_user File.read('./spec/kern/assets/choose_action_sync_no_goto.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    expect {
      ctx.evald %{
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.to raise_exception
  end

  it "Calling an asynchronous request for the Goto in choose_action will result in an exception" do
    ctx = flok_new_user File.read('./spec/kern/assets/choose_action_sync.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    expect {
      ctx.evald %{
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.to raise_error(/choose_action.*Goto/)
  end
end
