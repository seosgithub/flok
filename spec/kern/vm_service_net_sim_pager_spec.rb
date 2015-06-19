#The pg_mem0 pager

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service_net_sim_pager" do
  include Zlib
  include_context "kern"

  it "Can initialize the pg_net_sim pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_net_sim/nothing.rb'), File.read("./spec/kern/assets/vm/pg_net_sim/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    res = ctx.eval("pg_net_sim_spec_did_init")
    expect(res).to eq(true)
  end

  it "Can load the pg_net_sim pager with data" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_net_sim/nothing.rb'), File.read("./spec/kern/assets/vm/pg_net_sim/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      var json = #{File.read("./spec/kern/assets/vm/pg_net_sim/pages.json")};
      pg_net_sim_load_pages(json)
    }

    pg_net_sim_stored_pages = ctx.dump("pg_net_sim_stored_pages")
    res = ctx.eval("pg_net_sim_spec_did_init")
    expect(res).to eq(true)

    #Simulate cache build for pages, the pg_net_sim stores like vm_cache from array
    pages = JSON.parse(File.read("./spec/kern/assets/vm/pg_net_sim/pages.json"))
    pages_cache = {}
    pages.each do |p|
      pages_cache[p["_id"]] = p
    end
    expect(pg_net_sim_stored_pages).to eq(pages_cache)
  end

  it "Can watch pg_net_sim and not get a response back before 2 seconds (by design)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_net_sim/watch.rb'), File.read("./spec/kern/assets/vm/pg_net_sim/config.rb") 
    ctx.eval %{
      var json = #{File.read("./spec/kern/assets/vm/pg_net_sim/pages.json")};
      pg_net_sim_load_pages(json)

      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    expect {
      pages = JSON.parse(File.read("./spec/kern/assets/vm/pg_net_sim/pages.json"))
      read_res_params = ctx.dump("read_res_params")
      expect(read_res_params).to eq(pages[0])
    }.to raise_error
  end

  it "Can watch pg_net_sim and get a response back after 2 seconds" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_net_sim/watch.rb'), File.read("./spec/kern/assets/vm/pg_net_sim/config.rb") 
    ctx.eval %{
      var json = #{File.read("./spec/kern/assets/vm/pg_net_sim/pages.json")};
      pg_net_sim_load_pages(json)

      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    (4*2).times do
      @driver.int "int_timer"
    end

    ctx.eval "int_dispatch([]);"

    pages = JSON.parse(File.read("./spec/kern/assets/vm/pg_net_sim/pages.json"))
    read_res_params = ctx.dump("read_res_params")
    expect(read_res_params).to eq(pages[0])
  end
end
