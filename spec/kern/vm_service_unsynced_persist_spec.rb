#The vm service unsynced to ensure that the unsynced survives a restart
#by saving to the disk cache

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service unsynced (persist)" do
  include Zlib
  include_context "kern"

  it "Should have called vm_pg_sync_pagein after 2 seconds" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb")
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);
    }

    #Should not be loaded at this time
    expect(ctx.eval("vm_unsynced_paged_in")).to eq(false)

    #Call the timer for 2 seconds (should invoke the load for the pg_spec0_sync_request)
    (2*4).times do
      @driver.int "int_timer", []
    end

    #Should be loaded at this time
    expect(ctx.eval("vm_unsynced_paged_in")).to eq(true)
  end

  it "vm_pg_sync_pagein should make a disk request; and only once if called multiple times" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb")
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_sync_pagein();
      vm_pg_sync_pagein();

      int_dispatch([]);
    }

    #Should be loaded (manually called)
    expect(ctx.eval("vm_unsynced_paged_in")).to eq(true)

    #Should have made a disk request
    @driver.ignore_up_to "if_per_get", 2

    #Expect a request for the special page that holds vm_unsynced
    res = @driver.get "if_per_get", 2
    expect(res[1]).to eq("__reserved__")
    expect(res[2]).to eq("vm_unsynced")

    @driver.expect_not_to_contain "if_per_get"
  end

  it "vm_pg_sync_pagein should write out the read to vm_unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb")
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_sync_pagein();

      int_dispatch([]);
    }

    #Should be loaded (manually called)
    expect(ctx.eval("vm_unsynced_paged_in")).to eq(true)

    #Expect a request for the special page that holds vm_unsynced
    @driver.ignore_up_to "if_per_get", 2
    res = @driver.get "if_per_get", 2
    expect(res[1]).to eq("__reserved__")
    expect(res[2]).to eq("vm_unsynced")

    #Return the vm_unsynced
    @driver.int "int_per_get_res", [
      "vm",
      "__reserved__",
      "vm_unsynced",
      {
        "spec" => {
          "test" => 1
        }
      }
    ]

    #Expect vm_unsynced to have loaded the data
    res = @ctx.dump("vm_unsynced")
    expect(res).to eq({
        "spec" => {
          "test" => 1
        }
    })
  end

  it "vm_pg_sync_pagein should write out the read to vm_unsynced and merge if there are any existing elements" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5d.rb")
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_pg_sync_pagein();

      vm_unsynced = {
        "spec": {
          "foo": 0
        },

        "spec1": {
          "bar": 1
        }
      }

      int_dispatch([]);
    }

    #Should be loaded (manually called)
    expect(ctx.eval("vm_unsynced_paged_in")).to eq(true)

    #Expect a request for the special page that holds vm_unsynced
    @driver.ignore_up_to "if_per_get", 2
    res = @driver.get "if_per_get", 2
    expect(res[1]).to eq("__reserved__")
    expect(res[2]).to eq("vm_unsynced")

    #Return the vm_unsynced
    @driver.int "int_per_get_res", [
      "vm",
      "__reserved__",
      "vm_unsynced",
      {
        "spec" => {
          "holah" => 1,
        },
        "spec1" => {
        }
      }
    ]

    #Expect vm_unsynced to have loaded the data
    res = @ctx.dump("vm_unsynced")
    expect(res).to eq({
        "spec" => {
          "foo" => 0,
          "holah" => 1,
        },
        "spec1" => {
          "bar" => 1
        }
    })
  end

  it "vm_pg_sync_pageout should save the vm_unsynced data to disk; and only once on multiple calls" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb")
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_unsynced = {
        "spec": {
          "foo": 0
        },

        "spec1": {
          "bar": 1
        }
      }

      //Request a save
      vm_unsynced_is_dirty = true;
      vm_pg_sync_pageout();
      vm_pg_sync_pageout();

      int_dispatch([]);
    }

    #Expect a write out
    @driver.ignore_up_to "if_per_set", 2
    res = @driver.get "if_per_set", 2
    expect(res[0]).to eq("__reserved__")
    expect(res[1]).to eq("vm_unsynced")
    vm_unsynced_json = res[2]
    expect(JSON.parse(vm_unsynced_json)).to eq({
      "spec" => {
        "foo" => 0
      },
      "spec1" => {
        "bar" => 1
      }
    })

    #Should not have two requests
    @driver.expect_not_to_contain "if_per_set" 

    expect(ctx.eval("vm_unsynced_is_dirty")).to eq(false)
  end

  it "vm_pg_sync_pageout should be called periodically every 20 seconds" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5c.rb")
    dump = ctx.evald %{
      //Needed to initialize pagers
      base = _embed("my_controller", 0, {}, null);

      vm_unsynced = {
        "spec": {
          "foo": 0
        },

        "spec1": {
          "bar": 1
        }
      }

      //Ensure that pageout is going to be called
      vm_unsynced_is_dirty = true;

      int_dispatch([]);
    }

    #Expect no write out yet until 20s have passed
    @driver.expect_not_to_contain "if_per_set"
    (20*4).times do
      @driver.int "int_timer", []
    end

    #Now we expect a write out as 20s have passed
    #And the 0s should now be 1 because we called vm_pg_sync_wakeup() right before hand
    @driver.ignore_up_to "if_per_set"
    res = @driver.get "if_per_set", 2
    expect(JSON.parse(res[2])).to eq(
        "spec" => {
          "foo" => 1
        },

        "spec1" => {
          "bar" => 1
        }
    )

    #Wait again 20 seconds
    (20*4).times do
      @driver.int "int_timer", []
    end

    #Expect no write out as we are not dirty
    @driver.expect_not_to_contain "if_per_set"
  end
end
