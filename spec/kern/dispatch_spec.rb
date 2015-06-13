Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:dispatch_spec" do
  #Max number of items to be queued in queues other than main
  #per dispatch (as per specs)
  MAX_Q = 5
  
  include_context "kern"

  it "Can call spec_dispatch" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      spec_dispatch_q(main_q, 2);
    }

    main_q = ctx.dump "main_q"
    expect(main_q).to eq [[0, "spec"], [0, "spec"]]
  end

  it "Does disptach an unlimited number of items from the main queue" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      spec_dispatch_q(main_q, 10);
    }

    ctx.eval("int_dispatch([])")
    q = @driver.dump_q

    expect(q).to eq([[0, [0, "spec"]*10].flatten])
  end

  queues = [
    "main",
    "net",
    "disk",
    "cpu",
    "gpu"
  ]

  queues.each_with_index do |qname, qindex|
    #Don't do main queue
    next if qname == "main"
    
    it "Does not disptach an unlimited number of items from the #{qname} queue" do
      #Compile the controller
      ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

      #Register callout
      ctx.eval %{
        spec_dispatch_q(#{qname}_q, #{MAX_Q+1});
      }

      #Get partial queue, should have 'i' because we want more things than the max
      ctx.eval("int_dispatch([])")
      q = @driver.dump_q
      expect(q).to eq(['i', [qindex, [0, "spec"]*MAX_Q].flatten])
    end

    it "Does dispatch the rest of the items after the first two incomplete disptaches" do
      #Compile the controller
      ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

      #Register callout
      ctx.eval %{
        spec_dispatch_q(#{qname}_q, #{MAX_Q*3});
      }

      #Get partial queue, should have 'i' because we want more things than the max
      ctx.eval("int_dispatch([])")
      q = @driver.dump_q
      expect(q).to eq(['i', [qindex, [0, "spec"]*MAX_Q].flatten])

      #Get partial queue, should have 'i' because we want more things than the max
      ctx.eval("int_dispatch([])")
      q = @driver.dump_q
      expect(q).to eq(['i', [qindex, [0, "spec"]*MAX_Q].flatten])

      #Last piece, should not have an 'i'
      ctx.eval("int_dispatch([])")
      q = @driver.dump_q
      expect(q).to eq([[qindex, [0, "spec"]*MAX_Q].flatten])
    end


    it "Does disptach at MAX_Q number of items from the #{qname} queue" do
      #Compile the controller
      ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

      #Register callout
      ctx.eval %{
        spec_dispatch_q(#{qname}_q, #{MAX_Q});
      }

      ctx.eval("int_dispatch([])")
      q = @driver.dump_q

      expect(q).to eq([[qindex, [0, "spec"]*MAX_Q].flatten])
    end

    it "Does disptach all at (MAX_Q-1) number of items from the #{qname} queue" do
      #Compile the controller
      ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

      #Register callout
      ctx.eval %{
        spec_dispatch_q(#{qname}_q, #{MAX_Q}-1);
      }

      ctx.eval("int_dispatch([])")
      q = @driver.dump_q

      expect(q).to eq([[qindex, [0, "spec"]*(MAX_Q-1)].flatten])
    end
  end
end
