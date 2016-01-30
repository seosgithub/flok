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

  it "Contains a preloaded vm_cache, vm_dirty, and vm_notify_map for each namespace with a blank hash" do
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

  it "Can call vm_cache_write and save it to vm_cache[ns][id]" do 
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      var page = vm_create_page("test");

      //Save page
      vm_transaction_begin();
      vm_cache_write("user", page);
      vm_transaction_end();
    }

    vm_cache = JSON.parse(ctx.eval("JSON.stringify(vm_cache)"))
    page = JSON.parse(ctx.eval("JSON.stringify(page)"));

    #Expect the same hash
    expect(vm_cache).to eq({
      "user" => {
        page["_id"] => page
      }
    })
  end

  it "Can create a copy of pg_spec0 and receive the correct things in it's initialization" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config4.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    pg_spec0_init_params = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_init_params)"))

    #Expect options and ns to match in config4
    expect(pg_spec0_init_params).to eq({
      "ns" => "spec",
      "options" => {"hello" => "world"}
    })
  end

  it "Does call pagers watch function with a undefined page when no page exists in cache" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller7.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

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

  it "Does call pagers watch function with a page when the page requested for a watch is stored in cache" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller7.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    #We are going to manually store a page in cache as this page should be retrieved
    #for the watch attempt
    res = ctx.eval %{
      //Manually construct a page as we are going to test the watch function
      //which receives a call to watch with the hash of this page so the 
      //watch function can tell if the page has changed (e.g. if you are connecting)
      //to a remote server
      var page = vm_create_page("test");

      //Save page for the spec pager
      vm_transaction_begin();
      vm_cache_write("spec", page);
      vm_transaction_end();
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
    expect(pg_spec0_watchlist[0]["id"]).to eq("my_key")
  end

  it "does not throw an exception if multiple watches are attempted" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller_exc_2watch.rb'), File.read("./spec/kern/assets/vm/config6.rb") 

    expect {
      ctx.eval %{
        base = _embed("my_controller", 1, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.not_to raise_exception

    bp = ctx.eval("base")
    vm_notify_map = ctx.dump("vm_notify_map")
    vm_bp_to_nmap = ctx.dump("vm_bp_to_nmap")

    expect(vm_notify_map).to eq({
      "spec" => {
        "test" => [bp]
      },
      "spec1" => {}
    })

    expect(vm_bp_to_nmap).to eq({
      bp.to_s => {
        "spec" => {
          "test" => [[bp], 0]
        }
      }
    })

  end

  it "does not throw an exception if multiple unwatches are requested" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller_exc_ewatch.rb'), File.read("./spec/kern/assets/vm/config6.rb") 

    expect {
      ctx.eval %{
        base = _embed("my_controller", 1, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.not_to raise_exception

    bp = ctx.eval("base")
    vm_notify_map = ctx.dump("vm_notify_map")
    vm_bp_to_nmap = ctx.dump("vm_bp_to_nmap")

    expect(vm_notify_map).to eq({
      "spec" => {
      },
      "spec1" => {}
    })

    expect(vm_bp_to_nmap).to eq({
      bp.to_s  => {}
    })

  end

  it "does not throw an exception if unwatch is called before watch on a particular controller; but it was already watched at one point" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller_exc_ewatch2.rb'), File.read("./spec/kern/assets/vm/config6.rb") 

    expect {
      ctx.eval %{
        base = _embed("my_watch_controller", 1, {}, null);
        base = _embed("my_controller", 1, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.not_to raise_exception
  end

  it "does allow watch, unwatch, and then re-watch to work" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller_exc_ewatch3.rb'), File.read("./spec/kern/assets/vm/config6.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    bp = ctx.eval("base")
    vm_notify_map = ctx.dump("vm_notify_map")
    vm_bp_to_nmap = ctx.dump("vm_bp_to_nmap")

    expect(vm_notify_map).to eq({
      "spec" => {
        "test" => [bp]
      },
      "spec1" => {}
    })

    expect(vm_bp_to_nmap).to eq({
      bp.to_s => {
        "spec" => {
          "test" => [[bp], 0]
        }
      }
    })
  end

  it "does allow unwatch, watch, and then re-unwatch to work" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller_exc_ewatch4.rb'), File.read("./spec/kern/assets/vm/config6.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    bp = ctx.eval("base")
    vm_notify_map = ctx.dump("vm_notify_map")
    vm_bp_to_nmap = ctx.dump("vm_bp_to_nmap")

    expect(vm_notify_map).to eq({
      "spec" => {},
      "spec1" => {}
    })

    expect(vm_bp_to_nmap).to eq({
      bp.to_s => {
        "spec" => {
        }
      }
    })
  end

  it "multiple sequential watch requests from two controllers for a namespace do not hit the pager multiple times" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);
      base2 = _embed("my_controller", base+2, {}, null);

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

    @driver.int "int_per_get_res", ["vm", "spec", "test", nil]

    #Expect the page to be written to cache
    vm_cache = JSON.parse(ctx.eval("JSON.stringify(vm_cache)"));
    vm_write_list = JSON.parse(ctx.eval("JSON.stringify(vm_write_list[0])"));
    expect(vm_cache["spec"]["test"]).to eq(vm_write_list)
  end

  it "sends watch callback to controller when cache is written to via read_res" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller11.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Write will attempt to read disk first
    @driver.int "int_per_get_res", ["vm", "spec", "test", nil]

    #Read is asynchronous
    ctx.eval %{
      //Drain queue
      int_dispatch([]);
    }

    vm_write_list = JSON.parse(ctx.eval("JSON.stringify(vm_write_list[0])"));
    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    expect(read_res_params).to eq(vm_write_list)
  end

  it "non-sync watch does send two watch callbacks to a controller if there is cached content followed by a write" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller12.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);
    }

    #Step 1. Write a page into cache
    ################################################################################
    #Trigger controller 'write_first'
    @driver.int "int_event", [ ctx.eval("base"), "write_first", {} ]
    @ctx.eval %{ int_dispatch([]) }

    #Write should have trigger a disk read (to ensure there is no page in cache) vhich we respond
    #with nothing
    @driver.ignore_up_to "if_per_get"
    @driver.int "int_per_get_res", ["vm", "spec", "test", nil]
    ################################################################################

    #Step 2. Watch that page
    ################################################################################
    #Trigger controller 'watch_first'
    @driver.int "int_event", [ ctx.eval("base"), "watch_first", {} ]

    #Asynchronous dispatch
    100.times { @ctx.eval("int_dispatch([])")}

    #Should have triggered the read_res
    expect(@ctx.dump("read_res_params").count).to eq(1)
    ################################################################################
  end

  #Just read before you write!
  #it "vm_cache_write does not tell controllers an update has occurred if the page requested to cache was already cached" do
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller13.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    #dump = ctx.evald %{
      #dump.base = _embed("my_controller", 1, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #@driver.int "int_event", [dump["base"], "next", {}]

    #read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    #vm_write_list = JSON.parse(ctx.eval("JSON.stringify(vm_write_list)"));
    #expect(read_res_params).to eq([vm_write_list[0]])
  #end

  it "updates vm_notify_map when a watch takes place" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller14.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    vm_notify_map = JSON.parse(ctx.eval("JSON.stringify(vm_notify_map)"));
    expect(vm_notify_map).to eq({
      "spec" => {
        "test" => [base]
      }
    })
  end

  it "updates vm_bp_to_nmap when a watch takes place" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller14.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    vm_bp_to_nmap = JSON.parse(ctx.eval("JSON.stringify(vm_bp_to_nmap)"));
    expect(vm_bp_to_nmap).to eq({
      base.to_s => {
        "spec" => {
          "test" => [[3], 0]
        }
      }
    })

    #Removing the element from the given pointer in vm_bp_to_nmap to the array will also alter vm_notify_map's array
    #if it is a reference
    ctx.eval %{ 
      //Grab the array that contains [node, index] where node is a reference to an array of vm_notify_map[ns][key]
      var e = vm_bp_to_nmap[base]["spec"]["test"];
      var node = e[0];
      var index = e[1];

      //Remove an element from the node
      node.splice(index, 1);
    }

    vm_notify_map_after = JSON.parse(ctx.eval("JSON.stringify(vm_notify_map)"))
    expect(vm_notify_map_after).to eq({
      "spec" => {
        "test" => []
      }
    })
  end

  it "updates vm_notify_map when an unwatch takes place" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller15.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    vm_notify_map = JSON.parse(ctx.eval("JSON.stringify(vm_notify_map)"));
    expect(vm_notify_map).to eq({
      "spec" => {
      }
    })
  end

  it "updates vm_bp_to_nmap when an unwatch takes place" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller15.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    vm_bp_to_nmap = JSON.parse(ctx.eval("JSON.stringify(vm_bp_to_nmap)"));
    expect(vm_bp_to_nmap).to eq({
      base.to_s => {
        "spec" => {}
      }
    })
  end

  it "Does not crash when a new a controller disconnects without watches" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16b.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    #vm_bp_To_nmap should be blank
    base = ctx.eval("base")
    vm_bp_to_nmap = JSON.parse(ctx.eval("JSON.stringify(vm_bp_to_nmap)"));
    expect(vm_bp_to_nmap).to eq({})

    #vm_notify_map should not contain the entries for the base address anymore
    base = ctx.eval("base")
    vm_notify_map = JSON.parse(ctx.eval("JSON.stringify(vm_notify_map)"));
    expect(vm_notify_map).to eq({
      "spec" => {
      }
    })
  end

  it "Erases entries in vm_bp_to_nmap and vm_notify_map for a controller that disconnects" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16q.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    #vm_bp_To_nmap should be blank
    base = ctx.eval("base")
    vm_bp_to_nmap = JSON.parse(ctx.eval("JSON.stringify(vm_bp_to_nmap)"));
    expect(vm_bp_to_nmap).to eq({})

    #vm_notify_map should not contain the entries for the base address anymore
    base = ctx.eval("base")
    vm_notify_map = JSON.parse(ctx.eval("JSON.stringify(vm_notify_map)"));
    expect(vm_notify_map).to eq({
      "spec" => {
        "test" => [],
        "test2" => []
      }
    })
  end

  it "Erases entries in vm_bp_to_nmap and vm_notify_map for a controller that disconnects with two controllers maintaining correct" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    #vm_bp_To_nmap should be blank
    base = ctx.eval("base")
    vm_bp_to_nmap = JSON.parse(ctx.eval("JSON.stringify(vm_bp_to_nmap)"));
    expect(vm_bp_to_nmap).to eq({})

    #vm_notify_map should not contain the entries for the base address anymore
    base = ctx.eval("base")
    vm_notify_map = JSON.parse(ctx.eval("JSON.stringify(vm_notify_map)"));
    expect(vm_notify_map).to eq({
      "spec" => {
        "test" => []
      }
    })
  end

  it "unwatches all watched pages when a controller disconnects" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    pg_spec0_unwatchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_unwatchlist)"))
    expect(pg_spec0_unwatchlist).to eq(["test"])
  end

  it "does not make multiple calls to unwatch in the event the page is not fully unwatched yet" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16c.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    pg_spec0_unwatchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_unwatchlist)"))
    expect(pg_spec0_unwatchlist).to eq([])
  end

  it "does unwatch after both watches are cancelled" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16d.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    pg_spec0_unwatchlist = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_unwatchlist)"))
    expect(pg_spec0_unwatchlist).to eq([])
  end



  it "Stores dirty pages written via vm_cache_write in vm_dirty" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      page = {
        _head: "a",
        _next: "b",
        _id: "hello",
        _type: "array",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      vm_rehash_page(page);

      //Save page
      vm_transaction_begin();
      vm_cache_write("user", page);
      vm_transaction_end();
    }

    vm_dirty = JSON.parse(ctx.eval("JSON.stringify(vm_dirty)"))
    page = JSON.parse(ctx.eval("JSON.stringify(page)"));

    #Expect the same hash
    expect(vm_dirty).to eq({
      "user" => {
        page["_id"] => page
      }
    })
  end

  it "Does not try to write to disk when the pageout runs but a disk read has not come back yet" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller18.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now* which wont do anything yet because
      //we haven't responded to the read request yet so its not
      //going to actually pageout until we respond to the read
      //and then call pageout again
      vm_pageout();

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #Shouldn't have gotten a 'set' yet, because we haven't sent a page back
    expect {
      @driver.ignore_up_to "if_per_set", 2
    }.to raise_error /Waited/

    @driver.ignore_up_to "if_per_get", 2
    #Respond to get
    @driver.int "int_per_get_res", ["vm", "spec", "test", {
      "_id" => "test",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #Call pageout again after we respond to the if_per_get
    ctx.eval %{
      vm_pageout();
      int_dispatch([]);
    }

    #Should have gotten a set request
    @driver.ignore_up_to "if_per_set", 2
  end

  it "Does attempt " do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller18.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    expect {
      @driver.ignore_up_to "if_per_get", 2
    }.to raise_error /Waited/
  end


  it "Does send a read request from disk cache when watching a key for the first time" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 2
    @driver.mexpect("if_per_get", ["vm", "spec", "test"], 2)
  end

  it "Does send a read request from disk cache when synchronously reading a key for the first time via read_sync" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19c.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "test"], 0)

    @driver.int "int_per_get_res", ["vm", "spec", "test", {
      "_id" => "test",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    @driver.mexpect("if_per_get", ["vm", "spec", "test2"], 0)

    @driver.int "int_per_get_res", ["vm", "spec", "test3", {
      "_id" => "test2",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    dump = ctx.evald %{
      dump.read_sync_res_params = read_sync_res_params;
    }

    expect(dump["read_sync_res_params"].length).to eq(2)
    expect(dump["read_sync_res_params"][0]["_id"]).to eq("test")
    expect(dump["read_sync_res_params"][1]["_id"]).to eq("test2")
  end

  it "Does send a read request from disk cache when synchronously reading a key for the first time via read_sync, and returns a blank hash if the page does not exist" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19h.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "test"], 0)

    #Send back blank result (Send two to make sure we only get one result back)
    @driver.int "int_per_get_res", ["vm", "spec", "test", nil]
    @driver.int "int_per_get_res", ["vm", "spec", "test", nil]

    dump = ctx.evald %{
      dump.read_sync_res_params = read_sync_res_params;
    }

    expect(dump["read_sync_res_params"].length).to eq(1)
    expect(dump["read_sync_res_params"][0]).to eq({})
  end

  it "Calling read_sync on an entry that already exists in cache will not trigger a disk read" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19d.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    #Expect to have gotten one disk read request
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "test"], 0)

    #Send the disk read response back controller19d:14
    @driver.int "int_per_get_res", ["vm", "spec", "test", {
      "_id" => "test",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #Send the 'get_test' event which should trigger a disk read
    ctx.eval %{
      int_dispatch([3, "int_event", base, "get_test", {}])
    }

    #We should not get second if_per_get request because the data was already cached
    #by the first request
    expect {
      @driver.ignore_up_to "if_per_get", 0
    }.to raise_exception
  end

  it "Calling read_sync on two consecutive controllers within the same frame (i.e no change for int_dispatch to be invoked to drain queue), will result in both controllers getting correct copy of data and not out of order sync_reads as they have to be pulled from the vm_read_sync_in_progress queue to discover the read_sync request base pointer" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19e.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Expect to have gotten two disk read request, one for test1 and one for test2
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "test1"], 0)
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "test2"], 0)

    #Send the disk read response back for the first controller (my_controller)
    @driver.int "int_per_get_res", ["vm", "spec", "test1", {
      "_id" => "test1",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #Send the disk read response back for the second controller (my_other_controller)
    @driver.int "int_per_get_res", ["vm", "spec", "test2", {
      "_id" => "test2",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #The read_sync of each controller should match up with the page it requested
    dump = @ctx.evald %{
      dump.my_controller_read_sync_res = my_controller_read_sync_res;
      dump.my_other_controller_read_sync_res = my_other_controller_read_sync_res;
    }

    expect(dump["my_controller_read_sync_res"]["_id"]).to eq("test1")
    expect(dump["my_other_controller_read_sync_res"]["_id"]).to eq("test2")
  end

  it "Calling read_sync on frame0 for page 'A' on controller0 and then on frame1 for page 'A' on controller1 and page 'B' on controller2 will result in all controllers receiving the correct pages" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19f.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    dump = ctx.evald %{
      dump.controller0_base = _embed("controller0", 1, {}, null);
      dump.controller1_base = controller1_base; 
      dump.controller2_base = controller2_base; 

      //Drain queue
      int_dispatch([]);
    }

    #Expect the first request for controller0 for pageA
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "A"], 0)

    #Send the disk read response back for controller0 pageA
    @driver.int "int_per_get_res", ["vm", "spec", "A", {
      "_id" => "A",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #Now signal to controller1 & controller2 to grab their pages
    @driver.int "int_event", [dump["controller1_base"], "get", {}]
    @driver.int "int_event", [dump["controller2_base"], "get", {}]

    #We shouldn't receive 'A' because it will be retrieved by the cache read
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "B"], 0)

    #Send the disk read response back for frame1 'B' for controller2
    @driver.int "int_per_get_res", ["vm", "spec", "B", {
      "_id" => "B",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #The read_sync of each controller should match up with the page it requested
    dump = @ctx.evald %{
      dump.controller1_read_sync_res = controller1_read_sync_res;
      dump.controller2_read_sync_res = controller2_read_sync_res;
    }

    expect(dump["controller1_read_sync_res"]["_id"]).to eq("A")
    expect(dump["controller2_read_sync_res"]["_id"]).to eq("B")
  end

  it "Calling read_sync on frame0 for page 'B' on controller0 and then on frame1 for page 'A' on controller1 and page 'B' on controller2 will result in all controllers receiving the correct pages (reversed order from above)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19g.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    dump = ctx.evald %{
      dump.controller0_base = _embed("controller0", 1, {}, null);
      dump.controller1_base = controller1_base; 
      dump.controller2_base = controller2_base; 

      //Drain queue
      int_dispatch([]);
    }

    #Expect the first request for controller0 for pageB
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "B"], 0)

    #Send the disk read response back for controller0 pageB
    @driver.int "int_per_get_res", ["vm", "spec", "B", {
      "_id" => "B",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #Now signal to controller1 & controller2 to grab their pages
    @driver.int "int_event", [dump["controller1_base"], "get", {}]
    @driver.int "int_event", [dump["controller2_base"], "get", {}]

    #We shouldn't receive 'B' because it will be retrieved by the cache read
    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "A"], 0)

    #Send the disk read response back for frame1 'A' for controller2
    @driver.int "int_per_get_res", ["vm", "spec", "A", {
      "_id" => "A",
      "_hash" => nil,
      "_next" => nil,
      "entries" => [],
    }]

    #The read_sync of each controller should match up with the page it requested
    dump = @ctx.evald %{
      dump.controller1_read_sync_res = controller1_read_sync_res;
      dump.controller2_read_sync_res = controller2_read_sync_res;
    }

    expect(dump["controller1_read_sync_res"]["_id"]).to eq("A")
    expect(dump["controller2_read_sync_res"]["_id"]).to eq("B")
  end

  it "Does send a sync read request from disk cache when watching a key for the first time with sync: true" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19b.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "test"], 0)
  end

  it "Only sends one disk read request when multiple non-sync watches are attempted" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);
      base2 = _embed("my_controller", base+2, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 2
    @driver.get "if_per_get", 2

    #There should not be another request for the drive
    expect {
      @driver.ignore_up_to "if_per_get"
    }.to raise_error /Waited/
  end

  it "A watch request with the sync flag enabled does trigger a synchronous read for a non-existant page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8ws.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "my_key"], 0)
  end

  it "A watch request with the sync flag enabled does return null to read_res if the page does not exist (really an illegal condition, page should always be avaliable if you're doing a watch with sync)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8ws.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "my_key"], 0)

    #Send back a blank page
    @driver.int "int_per_get_res", ["vm", "spec", "my_key", nil]

    read_res_params = ctx.dump "read_res_params"
    expect(read_res_params).to eq([{}])
  end

  it "A watch request with the sync flag enabled does not send two read_res back after int_dispatch" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8ws.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "my_key"], 0)

    #Send back a blank page
    @driver.int "int_per_get_res", ["vm", "spec", "my_key", nil]

    #Dispatch any pending async
    #should not do anything here
    @ctx.eval %{
      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }
    }

    read_res_params = ctx.dump "read_res_params"
    expect(read_res_params).to eq([{}])
  end

  it "A watch request with the sync flag enabled does return the page to read_res" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8ws.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "my_key"], 0)

    #Send back a real page
    @driver.int "int_per_get_res", ["vm", "spec", "my_key", {
      "_id" => "my_key",
      "entries" => [],
      "_head" => nil,
      "_next" => nil
    }]

    #Dispatch any pending async
    #should not do anything here
    @ctx.eval %{
      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }
    }

    read_res_params = ctx.dump "read_res_params"
    expect(read_res_params[0]["_id"]).to eq("my_key")
    expect(read_res_params.length).to eq(1)
  end

  it "A watch request with the sync flag enabled does return the page to read_res followed by all future changes being sent asynchronously" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8ws2.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //We need another controller, plans to synchronously dispatch
      //changes within the same controller
      other_base = _embed("my_other_controller", base+2, {}, null);

      //Drain queue
      int_dispatch([]);
    }
    base = ctx.eval("base")
    other_base = ctx.eval("other_base")

    @driver.ignore_up_to "if_per_get", 0
    @driver.mexpect("if_per_get", ["vm", "spec", "my_key"], 0)

    #Send back a real page
    @driver.int "int_per_get_res", ["vm", "spec", "my_key", {
      "_id" => "my_key",
      "entries" => [],
      "_head" => nil,
      "_next" => nil
    }]

    #Dispatch any pending async
    #should not do anything here
    @ctx.eval %{
      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }
    }

    read_res_params = ctx.dump "read_res_params"
    expect(read_res_params[0]["_id"]).to eq("my_key")
    expect(read_res_params.length).to eq(1)

    #Signal controller to modify page
    @driver.int "int_event", [other_base, "modify_page", {}]

    #Expect nothing to show up yet (should be dispatched asynchrosouly and will show up after int_dispatch
    read_res_params = ctx.dump "read_res_params"
    expect(read_res_params.length).to eq(1)

    #Dispatch any pending async
    #(This should trigger an additional read_res)
    @ctx.eval %{
      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }
    }

    read_res_params = ctx.dump "read_res_params"
    expect(read_res_params.length).to eq(2)
  end

  it "Clears the dirty page when pageout runs" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller18.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    ctx.eval("vm_pageout()");

    vm_dirty = JSON.parse(ctx.eval("JSON.stringify(vm_dirty)"))
    expect(vm_dirty).to eq({
      "spec" => {}
    })
  end

  #it "Responds twice to watch with a missing cache but where the disk has a copy and then the pager responds" do
  #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller20.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

  #ctx.eval %{
  #base = _embed("my_controller", 1, {}, null);

  #//Manually construct a page
  #page = {
  #_head: null,
  #_next: null,
  #_id: "hello",
  #entries: [
  #{_id: "hello2", _sig: "nohteunth"},
  #]
  #}

  #//Manually construct another page that would normally be written
  #//by a 'pager' to the cache
  #page2 = {
  #_head: null,
  #_next: null,
  #_id: "hello",
  #entries: [
  #{_id: "hello2", _sig: "nohteunth"},
  #{_id: "hello3", _sig: "athoeuntz"}
  #]
  #}

  #//Recalculate hashes
  #vm_rehash_page(page);
  #vm_rehash_page(page2);

  #//Drain queue
  #int_dispatch([]);
  #}

  ##Copies of JS pages in ruby dictionary format
  #page = JSON.parse(ctx.eval("JSON.stringify(page)"))
  #page2 = JSON.parse(ctx.eval("JSON.stringify(page2)"))

  ##At this point, flok should have attempted to grab a page to fill
  ##the *now* blank cache. We are going to send it the first page.
  #@driver.ignore_up_to "if_per_get", 2
  #@driver.get "if_per_get", 2
  #@driver.int "int_per_get_res", ["vm", "spec", page]

  ##Now, we pretend that a pager has written to the cache because it has
  ##received data back
  #ctx.eval(%{vm_cache_write("spec", page2)})

  #res = JSON.parse(ctx.eval("JSON.stringify(read_res)"))
  #expect(res).to eq([
  #page, page2
  #])
  #end

  it "Responds once to watch with a missing cache but where the pager responds before the disk for array" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller20.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Manually construct a page
      page = {
        _head: null,
        _next: null,
        _id: "hello",
        _type: "array",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      //Manually construct another page that would normally be written
      //by a 'pager' to the cache
      page2 = {
        _head: null,
        _next: null,
        _id: "hello",
        _type: "array",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
          {_id: "hello3", _sig: "athoeuntz"}
        ]
      }

      //Recalculate hashes
      vm_rehash_page(page);
      vm_rehash_page(page2);

      //Drain queue
      int_dispatch([]);
    }

    #Copies of JS pages in ruby dictionary format
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    page2 = JSON.parse(ctx.eval("JSON.stringify(page2)"))

    #At this point, flok should have attempted to grab a page to fill
    #the *now* blank cache. We are going to send it the first page.
    @driver.ignore_up_to "if_per_get", 2
    @driver.get "if_per_get", 2

    #Now, we pretend that a pager has written to the cache because it has
    #received data back
    ctx.eval(%{vm_cache_write("spec", page2)})

    #And then we let the cache from disk reply, which should be ignored
    #because the cache is already there from the pager
    @driver.int "int_per_get_res", ["vm", "spec", page["_id"], page]

    res = JSON.parse(ctx.eval("JSON.stringify(read_res)"))
    expect(res).to eq([
      page2
    ])
  end

  it "Responds once to watch with a missing cache but where the pager responds before the disk for hash" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller20.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Manually construct a page
      page = {
        _head: null,
        _next: null,
        _id: "hello",
        _type: "hash",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      //Manually construct another page that would normally be written
      //by a 'pager' to the cache
      page2 = {
        _head: null,
        _next: null,
        _id: "hello",
        _type: "hash",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
          {_id: "hello3", _sig: "athoeuntz"}
        ]
      }

      //Recalculate hashes
      vm_rehash_page(page);
      vm_rehash_page(page2);

      //Drain queue
      int_dispatch([]);
    }

    #Copies of JS pages in ruby dictionary format
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    page2 = JSON.parse(ctx.eval("JSON.stringify(page2)"))

    #At this point, flok should have attempted to grab a page to fill
    #the *now* blank cache. We are going to send it the first page.
    @driver.ignore_up_to "if_per_get", 2
    @driver.get "if_per_get", 2

    #Now, we pretend that a pager has written to the cache because it has
    #received data back
    ctx.eval(%{vm_cache_write("spec", page2)})

    #And then we let the cache from disk reply, which should be ignored
    #because the cache is already there from the pager
    @driver.int "int_per_get_res", ["vm", "spec", page["_id"], page]

    res = JSON.parse(ctx.eval("JSON.stringify(read_res)"))
    expect(res).to eq([
      page2
    ])
  end

  it "Does within 21 seconds of a write on bootup, write to disk" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller18.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    (4*21).times do
      @driver.int "int_timer", []
    end

    @driver.ignore_up_to "if_per_set", 2
    @driver.mexpect("if_per_set", ["spec", page["_id"], page], 2)
  end

  it "Does not attempt to write twice to disk after 41 seconds if there is no pending data to write" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller21.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    (4*41).times do
      @driver.int "int_timer", []
    end

    @driver.ignore_up_to "if_per_set", 2
    @driver.mexpect("if_per_set", ["spec", page["_id"], page], 2)

    expect {
      @driver.ignore_up_to "if_per_set"
    }.to raise_exception
  end

  it "Does attempt to write twice to disk after 41 seconds if there is pending data to write" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller21.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    (4*21).times do
      @driver.int "int_timer", []
    end

    @driver.ignore_up_to "if_per_set", 2
    @driver.mexpect("if_per_set", ["spec", page["_id"], page], 2)

    #Call next on controller which will write an new page
    ctx.eval %{ int_dispatch([3, "int_event", base, "next", {}]); }

    page2 = JSON.parse(ctx.eval("JSON.stringify(page2)"))
    (4*21).times do
      @driver.int "int_timer", []
    end

    @driver.ignore_up_to "if_per_set", 2
    @driver.mexpect("if_per_set", ["spec", page2["_id"], page2], 2)
  end

  it "Can create a copy of pg_spec0 and pg_spec1 and receive the correct things in it's initialization" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    pg_spec0_init_params = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_init_params)"))
    pg_spec1_init_params = JSON.parse(ctx.eval("JSON.stringify(pg_spec1_init_params)"))

    #Expect options and ns to match in config5
    expect(pg_spec0_init_params).to eq({
      "ns" => "spec0",
      "options" => {"hello" => "world"}
    })

    #Expect options and ns to match in config5
    expect(pg_spec1_init_params).to eq({
      "ns" => "spec1",
      "options" => {"foo" => "bar"}
    })
  end

  it "Does send a disk read request when attempting to write to a page that dosen't exist in vm_cache (that page may exist on disk and will need to be commited over)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller23.rb'), File.read("./spec/kern/assets/vm/config5b.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Expect a if_per_get request attempt
    @driver.ignore_up_to "if_per_get", 2
    @driver.mexpect "if_per_get", [
      "vm",
      "dummy",
      "test"
    ], 2
  end

  it "Does *not* send a disk read request when attempting to write to a page that dosen't exist in vm_cache (that page may exist on disk and will need to be commited over)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller23.rb'), File.read("./spec/kern/assets/vm/config5b.rb") 
    ctx.eval %{
      //Fake existance of a page
      var page = vm_create_page("test");
      vm_rehash_page(page);
      vm_reindex_page(page);
      vm_cache["dummy"]["test"] = page;

      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Expect not to get an if_per_get request attempt (it's already cached)
    @driver.expect_not_to_contain "if_per_get"
  end


  it "Does notify the pager of a write when a controller originally made a write request for a non-cached entry when that disk read returns without a page (null)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller23.rb'), File.read("./spec/kern/assets/vm/config5b.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    #Expect a if_per_get request attempt
    @driver.ignore_up_to "if_per_get", 2
    @driver.mexpect "if_per_get", [
      "vm",
      "dummy",
      "test"
    ], 2

    #Respond with a blank page (page does not exist on disk)
    @driver.int "int_per_get_res", [
      "vm",
      "dummy",
      "test",
      nil
    ]

    #Expect the pager to have received a write request by now
    dump = ctx.evald %{
      dump.pg_dummy0_write_vm_cache_clone = pg_dummy0_write_vm_cache_clone 
    }

    expect(dump["pg_dummy0_write_vm_cache_clone"]).to eq([
      {"dummy" => {}}
    ])
  end

  it "Does notify the pager of a write when a controller originally made a write request for a non-cached entry when that disk read returns with a page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller23.rb'), File.read("./spec/kern/assets/vm/config5b.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Expect a if_per_get request attempt
    @driver.ignore_up_to "if_per_get", 2
    @driver.mexpect "if_per_get", [
      "vm",
      "dummy",
      "test"
    ], 2

    #Respond with a blank page (page does not exist on disk)
    @driver.int "int_per_get_res", [
      "vm",
      "dummy",
      "test",
      {
        "_id" => "test",
        "_next" => nil,
        "_head" => nil,
        "entries" => []
      }
    ]

    #Expect the pager to have received a write request by now, and the dummy pager saves everything
    #it gets into a special variable queue (copied via deep clone of vm_cache)
    dump = ctx.evald %{
      dump.pg_dummy0_write_vm_cache_clone = pg_dummy0_write_vm_cache_clone 
    }
    expect(dump["pg_dummy0_write_vm_cache_clone"].length).to eq(1)
    expect(dump["pg_dummy0_write_vm_cache_clone"][0]["dummy"]["test"]).not_to eq(nil)
    expect(dump["pg_dummy0_write_vm_cache_clone"][0]["dummy"]["test"]["_id"]).to eq("test")
  end

  it "Does throw an exception if two writes are attempted in the same frame for a non-cached page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller23b.rb'), File.read("./spec/kern/assets/vm/config5b.rb") 
    expect {
      ctx.eval %{
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.to raise_error(/.*multiple.*/)
  end
end
