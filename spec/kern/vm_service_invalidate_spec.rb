#Testing support of the invalidate command

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service" do
  include Zlib
  include_context "kern"

  it "Can make an invalidate request to the vm pager without throwing an error" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/invalidate/controller0.rb'), File.read("./spec/kern/assets/vm/invalidate/config0.rb") 
    ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    #We need to signal that we retrieved the request to read and it came back negative
    @driver.ignore_up_to "if_per_get"
    @driver.int "int_per_get_res", ["vm", "user", "test", nil]

    @driver.int "int_event", [ctx.eval("base"), "next_clicked", {}]
    dump = ctx.evald %{
      int_dispatch([]);
      int_dispatch([]);
      dump.read_res_params = read_res_params
      dump.invalidate_res = invalidate_res
    }

    expect(dump["read_res_params"]["_id"]).to eq("test")

    expect(dump["invalidate_res"]["id"]).to eq("test")
    expect(dump["invalidate_res"]["ns"]).to eq("user")
  end

  it "Can make an invalidate request to the vm pager with an invalid page id without throwing an error" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/invalidate/controller0b.rb'), File.read("./spec/kern/assets/vm/invalidate/config0.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    #We need to signal that we retrieved the request to read and it came back negative
    @driver.ignore_up_to "if_per_get"
    @driver.int "int_per_get_res", ["vm", "user", "test", nil]

    @driver.int "int_event", [ctx.eval("base"), "next_clicked", {}]

    expect(ctx).to include_in_kernel_log /Attempted to invalidate/
  end

  it "Invalidation causes the page to be wiped from the vm cache & page-out will request that the page should be deleted." do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/invalidate/controller0.rb'), File.read("./spec/kern/assets/vm/invalidate/config0.rb") 
    ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    #We need to signal that we retrieved the request to read and it came back negative
    @driver.ignore_up_to "if_per_get"
    @driver.int "int_per_get_res", ["vm", "user", "test", nil]

    @driver.int "int_event", [ctx.eval("base"), "next_clicked", {}]
    dump = ctx.evald %{
      int_dispatch([]);
      int_dispatch([]);
      dump.read_res_params = read_res_params
      dump.invalidate_res = invalidate_res

      dump.vm_cache = vm_cache;

      vm_pageout();
      int_dispatch([]);

      dump.pg_spec0_watchlist = pg_spec0_watchlist
    }

    #vm cache should be wiped
    expect(dump["vm_cache"]["user"]["test"]).to eq(nil)

    #pager should have been asked for another watch request
    expect(dump["pg_spec0_watchlist"][1]).to eq({"id" => "test"})

    #page-out should request a deletion
    @driver.ignore_up_to "if_per_del", 2
    del_request = @driver.get "if_per_del", 2
    expect(del_request).to eq(["user", "test"])
  end

  it "page-out will /not/ request that the page should be deleted if the page was added back to the vm_cache before pageout runs" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/invalidate/controller1.rb'), File.read("./spec/kern/assets/vm/invalidate/config0.rb") 
    ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    #We need to signal that we retrieved the request to read and it came back negative
    @driver.ignore_up_to "if_per_get"
    @driver.int "int_per_get_res", ["vm", "user", "test", nil]

    @driver.int "int_event", [ctx.eval("base"), "next_clicked", {}]
    dump = ctx.evald %{
      int_dispatch([]);
      int_dispatch([]);
      dump.read_res_params = read_res_params
      dump.invalidate_res = invalidate_res

      dump.vm_cache = vm_cache;
    }

    @driver.ignore_up_to "if_per_get", 2
    res = @driver.get "if_per_get", 2
    @driver.int "int_per_get_res", ["vm", "user", "test", nil]

    dump = ctx.evald %{
      vm_pageout();
      int_dispatch([]);

      dump.pg_spec0_watchlist = pg_spec0_watchlist
    }

    #page-out should /not/ request a deletion
    expect {
      @driver.ignore_up_to "if_per_del", 2
    }.to raise_error /Waited/
  end
end
