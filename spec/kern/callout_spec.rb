Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:callout_spec" do
  include_context "kern"

it "Can register for single-shot a callout event 1 tick in the future" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      //Can accept an event via int_event
      function event_handler(ep, ename, info) {
        event_handler_ep = ep;
        event_handler_ename = ename;
      }
      reg_evt(9, event_handler);

      //Send the 'test' event in one tick to the 9 event function
      reg_timeout(9, "test", 1);
    }

    @driver.int("int_timer")

    ep = ctx.eval("event_handler_ep")
    ename = ctx.eval("event_handler_ename")
    expect(ep).to eq(9)
    expect(ename).to eq("test")
  end

 it "Can register for an interval callout event 1 tick in the future" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      //Can accept an event via int_event
      times_called = 0;
      function event_handler(ep, ename, info) {
        times_called += 1;
      }
      reg_evt(9, event_handler);

      //Send the 'test' event in one tick to the 9 event function
      reg_interval(9, "test", 1);
    }

    @driver.int("int_timer")
    @driver.int("int_timer")

    times_called = ctx.eval("times_called")
    expect(times_called).to eq(2);
  end

 it "only calls timeout event once" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      //Can accept an event via int_event
      times_called = 0;
      function event_handler(ep, ename, info) {
        times_called += 1;
      }
      reg_evt(9, event_handler);

      //Send the 'test' event in one tick to the 9 event function
      reg_timeout(9, "test", 1);
    }

    @driver.int("int_timer")
    @driver.int("int_timer")

    times_called = ctx.eval("times_called")
    expect(times_called).to eq(1);
  end

  it "does have nothing left in queue after one timeout" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      //Can accept an event via int_event
      function event_handler(ep, ename, info) {
      }
      reg_evt(9, event_handler);

      //Send the 'test' event in one tick to the 9 event function
      reg_timeout(9, "test", 1);
    }

    @driver.int("int_timer")

    res = JSON.parse(ctx.eval("JSON.stringify(callout_queue)"))
    expect(res).to eq({});
  end

  it "does have left in queue after interval" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      //Can accept an event via int_event
      function event_handler(ep, ename, info) {
      }
      reg_evt(9, event_handler);

      //Send the 'test' event in one tick to the 9 event function
      reg_interval(9, "test", 1);
    }

    @driver.int("int_timer")

    res = JSON.parse(ctx.eval("JSON.stringify(callout_queue)"))
    expect(res).not_to eq({});
  end

  it "does NOT have left in queue after interval if event receiver is gone" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      //Can accept an event via int_event
      times_called = 0;
      function event_handler(ep, ename, info) {
        times_called += 1;
      }
      reg_evt(9, event_handler);

      //Send the 'test' event in one tick to the 9 event function
      reg_interval(9, "test", 1);
    }

    @driver.int("int_timer")

    ctx.eval "dereg_evt(9);"
    @driver.int("int_timer")

    times_called = ctx.eval("times_called")
    expect(times_called).to eq(1);

    res = JSON.parse(ctx.eval("JSON.stringify(callout_queue)"))
    expect(res).to eq({});
  end
end
