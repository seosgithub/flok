Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:event_spec" do
  include_context "kern"

  it "Can call int_event_defer" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Register callout
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Queue up a deferred event
      int_event_defer(base, "defer_res", {});
    }

    edefer_q = ctx.dump("edefer_q")
    base = ctx.eval("base")
    expect(edefer_q).to eq([
      base, "defer_res", {}
    ])
  end

  it "Does call if_dispatch with an 'i' for incomplete" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Register callout
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Queue up two deferred event b/c the first will get eaten
      int_event_defer(base, "defer_res", {});
      int_event_defer(base, "defer_res", {});

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    #Incomplete should have been added
    q = @driver.dump_q
    expect(q[0]).to eq("i")
  end

  it "Does call the event trigger for the controller after the dispatch" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0defer.rb')

    #Register callout
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);
    }

    #At this point, the synchronous event should have been dispatched in the _embed
    #because int_event is located in the controller on_entry
    sync_res_params = ctx.dump("sync_res_params")
    expect(sync_res_params).to eq({
      "foo_sync" => "bar"
    })

    #But the deferred response should only be available during the
    #next int_disp
    expect {
      ctx.dump("defer_res_params")
    }.to raise_exception

    ctx.eval("int_dispatch([])")

    #At this point, we only have one int_dispatch, so the event
    #should never have been de-queued because it will on teh second one
    defer_res_params = ctx.dump("defer_res_params")
    expect(defer_res_params).to eq({
      "foo" => "bar"
    })
  end

  it "Does call the event trigger for the controller after the dispatch only one at a time" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0defer2.rb')

    #Register callout
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);
      int_dispatch([]);
    }

    #Should have dequeued the first asynchronous event callback
    defer_res_params = ctx.dump("defer_res_params")
    expect(defer_res_params).to eq({
      "foo" => "bar"
    })

    #But the second one should not have dequeued yet
    expect {
      ctx.dump("defer_res2_params")
    }.to raise_exception

    #Until we throw another int_dispatch
    ctx.eval("int_dispatch([])")

    #And now it should be there
    defer_res2_params = ctx.dump("defer_res2_params")
    expect(defer_res2_params).to eq({
      "foo" => "bar"
    })
  end
end
