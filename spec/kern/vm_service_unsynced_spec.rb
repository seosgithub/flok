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
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    vm_cache = ctx.dump("vm_cache")
    vm_dirty = ctx.dump("vm_dirty")
    vm_notify_map = ctx.dump("vm_notify_map")

    res = {
      "spec0" => {}, 
      "spec1" => {}
    }

    expect(vm_cache).to eq(res)
    expect(vm_dirty ).to eq(res)
    expect(vm_notify_map).to eq(res)
  end

  it "vm_pg_unmark_needs_sync does remove the entry from the vm_unsynced table and does not fail if the entry does not exist" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    vm_cache = ctx.dump("vm_cache")
    vm_dirty = ctx.dump("vm_dirty")
    vm_notify_map = ctx.dump("vm_notify_map")

    res = {
      "spec0" => {}, 
      "spec1" => {}
    }

    expect(vm_cache).to eq(res)
    expect(vm_dirty ).to eq(res)
    expect(vm_notify_map).to eq(res)
  end

  #Don't sync when it's 0 because the pager just added it and we don't want to sync to early. Wait til next pass
  it "vm_pg_sync_wakeup does increment any entries that are currently 0 to the value of 1 and does not invoke pager's sync for those entries" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    vm_cache = ctx.dump("vm_cache")
    vm_dirty = ctx.dump("vm_dirty")
    vm_notify_map = ctx.dump("vm_notify_map")

    res = {
      "spec0" => {}, 
      "spec1" => {}
    }

    expect(vm_cache).to eq(res)
    expect(vm_dirty ).to eq(res)
    expect(vm_notify_map).to eq(res)
  end

  it "vm_pg_sync_wakeup does *not* increment any entries that are currently *does* invoke pager's sync for those entries" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    vm_cache = ctx.dump("vm_cache")
    vm_dirty = ctx.dump("vm_dirty")
    vm_notify_map = ctx.dump("vm_notify_map")

    res = {
      "spec0" => {}, 
      "spec1" => {}
    }

    expect(vm_cache).to eq(res)
    expect(vm_dirty ).to eq(res)
    expect(vm_notify_map).to eq(res)
  end

end
