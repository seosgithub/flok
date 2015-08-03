#The vm service

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service" do
  include Zlib
  include_context "kern"

  it "vm_pg_mark_needs_sync does call the pagers sync routine and adds an entry in the vm_unsynced table with a value of 0" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb") 
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_mark_needs_sync("spec", "test");

      dump.vm_unsynced = vm_unsynced;
      dump.pg_spec0_sync_requests = pg_spec0_sync_requests;
    }

    expect(dump["vm_unsynced"]).to eq({
      "spec" => {
        "test" => 0
      }
    })

    expect(dump["pg_spec0_sync_requests"]).to eq(["test"])
  end

  it "vm_pg_unmark_needs_sync does remove the entry from the vm_unsynced table and does not fail if the entry does not exist" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb") 
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_mark_needs_sync("spec", "test");
      vm_pg_unmark_needs_sync("spec", "test");
      vm_pg_unmark_needs_sync("spec", "test_non_existant_key");

      dump.vm_unsynced = vm_unsynced;
    }

    expect(dump["vm_unsynced"]).to eq({
      "spec" => {
      }
    })
  end

  #Don't sync when it's 0 because the pager just added it and we don't want to sync to early. Wait til next pass
  it "vm_pg_sync_wakeup does increment any entries that are currently 0 to the value of 1 and does not invoke pager's sync for those entries" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb") 
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_mark_needs_sync("spec", "test");
      vm_pg_sync_wakeup();

      dump.vm_unsynced = vm_unsynced;
      dump.pg_spec0_sync_requests = pg_spec0_sync_requests;
    }

    expect(dump["vm_unsynced"]).to eq({
      "spec" => {
        "test" => 1
      }
    })

    #Only expect one entry, wakeup should have skipped the first try
    expect(dump["pg_spec0_sync_requests"]).to eq(["test"])
  end

  it "vm_pg_sync_wakeup does *not* increment any entries that are currently 1 and *does* invoke pager's sync for those entries" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb") 
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_mark_needs_sync("spec", "test");
      vm_pg_sync_wakeup();
      vm_pg_sync_wakeup();

      dump.vm_unsynced = vm_unsynced;
      dump.pg_spec0_sync_requests = pg_spec0_sync_requests;
    }

    expect(dump["vm_unsynced"]).to eq({
      "spec" => {
        "test" => 1
      }
    })

    #This time, we expect two entries because the second vm_sync_wakeup should have triggered it.
    expect(dump["pg_spec0_sync_requests"]).to eq(["test", "test"])
  end

  it "vm_pg_sync_wakeup is called every 20 seconds" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb") 

    #Mark page as needing sync
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_mark_needs_sync("spec", "test");
    }

    #Call the timer for 1 shot
    (20*4).times do
      @driver.int "int_timer", []
    end

    #First time, the vm_pg_sync_wakeup should not have triggered anything (vm_unsynced still set to 0)
    expect(ctx.dump("pg_spec0_sync_requests")).to eq(["test"])

    #Call the timer for 1 more shot
    (20*4).times do
      @driver.int "int_timer", []
    end

    #Second time, vm_pg_sync_wakeup should call pager's sync function
    expect(ctx.dump("pg_spec0_sync_requests")).to eq(["test", "test"])

    #Call the timer for 1 more shot
    (20*4).times do
      @driver.int "int_timer", []
    end

    #Third time, vm_pg_sync_wakeup should call pager's sync function
    expect(ctx.dump("pg_spec0_sync_requests")).to eq(["test", "test", "test"])
  end
end
