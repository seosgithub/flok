#The pg_mem0 pager

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service_mem_pagers" do
  include Zlib
  include_context "kern"

  it "Can initialize the pg_mem0 pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_mem/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    res = ctx.eval("pg_mem0_spec_did_init")
    expect(res).to eq(true)
  end

  it "Can make a write request to pg_mem0 and have that written in cache" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_mem/write.rb'), File.read("./spec/kern/assets/vm/pg_mem/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page = ctx.dump "page"
    vm_cache = ctx.dump("vm_cache")
    expect(page).to eq(vm_cache["local"]["test"])
  end

  it "Can initialize the pg_mem1 pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_mem/config1.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    res = ctx.eval("pg_mem1_spec_did_init")
    expect(res).to eq(true)
  end

  it "Can make a write request to pg_mem1 and have that written in cache" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_mem/write.rb'), File.read("./spec/kern/assets/vm/pg_mem/config1.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page = ctx.dump "page"
    vm_cache = ctx.dump("vm_cache")
    expect(page).to eq(vm_cache["local"]["test"])
  end

  it "Can initialize the pg_mem2 pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_mem/config2.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    res = ctx.eval("pg_mem2_spec_did_init")
    expect(res).to eq(true)
  end

  it "Can make a write request to pg_mem2 and have that written in cache" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_mem/write.rb'), File.read("./spec/kern/assets/vm/pg_mem/config2.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page = ctx.dump "page"
    vm_cache = ctx.dump("vm_cache")
    expect(page).to eq(vm_cache["local"]["test"])
  end

  it "Can use pg_mem0 and pg_mem1 at the same time" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_mem/write2.rb'), File.read("./spec/kern/assets/vm/pg_mem/config3.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page = ctx.dump "page"
    page2 = ctx.dump "page2"
    vm_cache = ctx.dump("vm_cache")
    expect(page).to eq(vm_cache["local0"]["test"])
    expect(page2).to eq(vm_cache["local1"]["test"])
  end
end
