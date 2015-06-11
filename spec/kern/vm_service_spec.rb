#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service" do
  include Zlib
  include_context "kern"

 #it "Can be used inside a controller" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config0.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")
    #res = ctx.eval("vm_did_wakeup")
    #expect(res).to eq(true)
  #end

 #it "Does pass options to spec0 in init" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")
    #res = JSON.parse(ctx.eval("JSON.stringify(spec0_init_options)"))
    #expect(res).to eq({"hello" => "world"})
  #end

 #it "Can include the spec0 pager and call read_sync" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller1.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the vm service is getting the read_sync request
    #res = ctx.eval("vm_read_sync_called")
    #expect(res).to eq(true)

    ##Verify that the vm service is disptaching the request
    #res = ctx.eval("spec0_read_sync_called")
    #expect(res).to eq(true)
  #end

  #it "Can include the spec0 pager and call read_sync and then get a reply" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller1.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the read did return from the spec0 pager
    #res = ctx.eval("read_res_params")
    #expect(res).not_to eq(nil)
  #end


  #it "Can include the spec0 pager and call read and then get a reply" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller2.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the read did return from the spec0 pager
    #res = ctx.eval("read_res_params")
    #expect(res).not_to eq(nil)
  #end

  #it "Can include the spec0 pager and call write and and then read to get a reply" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller3.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the read did return from the spec0 pager
    #res = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    #expect(res).to eq({
      #"key" => 33,
      #"value" => 22
    #})
  #end

#  it "Write then read does will hit the pager for the read, a write is not guaranteed to be 1 to 1 but a read is, additionally, the reads only went through once" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller4.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #expect(ctx.eval("spec0_read_count")).to eq(1)
  #end

  #it "Can read through and then send another read_res for a change on the page" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller5.rb'), File.read("./spec/kern/assets/vm/config2.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##read_res from spec is called multiple times and returns an array of the parms
    #res = JSON.parse(ctx.eval("JSON.stringify(read_res_called_with)"))

    ##Expect 2 responses, first is cache miss, second is cache hit, third is cache updated
    #expect(res).to eq [
      #{"key" => "my_key", "value" => "a"},
      #{"key" => "my_key", "value" => "a"},
      #{"key" => "my_key", "value" => "b"}
    #]
  #end

  #it "Can watch a key and then be sent a read_res whenever that key changes" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller6.rb'), File.read("./spec/kern/assets/vm/config3.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Trigger notification
    #ctx.eval("spec2_spec_trigger()")

    ##read_res from spec is called multiple times and returns an array of the parms
    #res = JSON.parse(ctx.eval("JSON.stringify(read_res_called_with)"))

    ##Expect 2 responses, first is cache miss, second is cache hit, third is cache updated
    #expect(res).to eq [
      #{"key" => "my_key", "value" => "a"},
      #{"key" => "my_key", "value" => "a"},
      #{"key" => "my_key", "value" => "b"}
    #]
  #end

  #it "vm_rehash_page can calculate the hash correctly" do
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    ##Run the check
    #res = ctx.eval %{
      #//Manually construct a page
      #var page = {
        #_head: null,
        #_next: null,
        #_id: "hello",
        #entries: [
          #{_id: "hello2", _sig: "nohteunth"},
        #]
      #}

      #vm_rehash_page(page);
    #}

    ##Calculate hash ourselves
    #hash = crc32("hello")
    #hash = crc32("nohteunth", hash)
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    ##Expect the same hash
    #expect(page).to eq({
      #"_head" => nil,
      #"_next" => nil,
      #"_id" => "hello",
      #"entries" => [
        #{"_id" => "hello2", "_sig" => "nohteunth"}
      #],
      #"_hash" => hash.to_s
    #})
  #end

  #it "vm_rehash_page can calculate the hash correctly with head and next" do
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    ##Run the check
    #res = ctx.eval %{
      #//Manually construct a page
      #var page = {
        #_head: "a",
        #_next: "b",
        #_id: "hello",
        #entries: [
          #{_id: "hello2", _sig: "nohteunth"},
        #]
      #}

      #vm_rehash_page(page);
    #}

    ##Calculate hash ourselves
    #hash = crc32("a")
    #hash = crc32("b", hash)
    #hash = crc32("hello", hash)
    #hash = crc32("nohteunth", hash)
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    ##Expect the same hash
    #expect(page).to eq({
      #"_head" => "a",
      #"_next" => "b",
      #"_id" => "hello",
      #"entries" => [
        #{"_id" => "hello2", "_sig" => "nohteunth"}
      #],
      #"_hash" => hash.to_s
    #})
  #end

  #it "Can call vm_cache_write and save it to vm_cache[ns][id]" do 
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    ##Run the check
    #res = ctx.eval %{
      #//Manually construct a page
      #page = {
        #_head: "a",
        #_next: "b",
        #_id: "hello",
        #entries: [
          #{_id: "hello2", _sig: "nohteunth"},
        #]
      #}

      #vm_rehash_page(page);

      #//Save page
      #vm_cache_write("user", page);
    #}

    #vm_cache = JSON.parse(ctx.eval("JSON.stringify(vm_cache)"))
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"));

    ##Expect the same hash
    #expect(vm_cache).to eq({
      #"user" => {
        #page["_id"] => page
      #}
    #})
  #end

  #it "Can create a copy of pg_spec0 and receive the correct things in it's initialization" do
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config4.rb") 
    #ctx.eval %{
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #pg_spec0_init_params = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_init_params)"))

    ##Expect options and ns to match in config4
    #expect(pg_spec0_init_params).to eq({
      #"ns" => "spec",
      #"options" => {"hello" => "world"}
    #})
  #end

  #it "Does call pagers watch function with a undefined page when no page exists in cache" do
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller7.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    #ctx.eval %{
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##We are watching a page that should have been stored in cache at this point
    #pg_spec0_watchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_watchlist)"))

    ##Expect options and ns to match in config4
    #expect(pg_spec0_watchlist).to eq([{
      #"id" => "my_key"
    #}])
  #end

  it "Does call pagers watch function with a page when the page requested for a watch is stored in cache" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller7.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    #We are going to manually store a page in cache as this page should be retrieved
    #for the watch attempt
    res = ctx.eval %{
      //Manually construct a page as we are going to test the watch function
      //which receives a call to watch with the hash of this page so the 
      //watch function can tell if the page has changed (e.g. if you are connecting)
      //to a remote server
      page = {
        _head: "a",
        _next: "b",
        _id: "my_key",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      vm_rehash_page(page);

      //Save page for the spec pager
      vm_cache_write("spec", page);
    }

    #This hash was calculated during vm_rehash_page
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We are watching a page that should have been stored in cache at this point
    pg_spec0_watchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_watchlist)"))

    #Expect options and ns to match in config4
    expect(pg_spec0_watchlist).to eq([{
      "id" => "my_key",
      "page" => page
    }])
  end

  it "multiple sequential watch requests for a namespace do not hit the pager multiple times" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We are watching a page that should have been stored in cache at this point
    pg_spec0_watchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_watchlist)"))

    #Expect options and ns to match in config4
    expect(pg_spec0_watchlist).to eq([{
      "id" => "my_key"
    }])
  end

  it "unwatch request to pager does call the pagers unwatch function" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller9.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We are watching a page that should have been stored in cache at this point
    pg_spec0_unwatchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_unwatchlist)"))

    expect(pg_spec0_unwatchlist).to eq(["my_key"])
  end

  it "watch unwatch and watch request for a namespace does hit the pager multiple times" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller9.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We are watching a page that should have been stored in cache at this point
    pg_spec0_watchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_watchlist)"))

    #Expect options and ns to match in config4
    expect(pg_spec0_watchlist).to eq([{
      "id" => "my_key"
    }, {
      "id" => "my_key"
    }])
  end

  it "sends write requests to the pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller10.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We are watching a page that should have been stored in cache at this point
    pg_spec0_watchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_watchlist)"))

    #Expect options and ns to match in config4
    expect(pg_spec0_watchlist).to eq([{
      "id" => "my_key"
    }, {
      "id" => "my_key"
    }])
  end
end
