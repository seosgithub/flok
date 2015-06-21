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

  it "vm_rehash_page can calculate the hash correctly for arrays" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _head: null,
        _type: "array",
        _next: null,
        _id: "hello",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      vm_rehash_page(page);
    }

    #Calculate hash ourselves
    hash = crc32("hello")
    hash = crc32("nohteunth", hash)
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #Expect the same hash
    expect(page).to eq({
      "_head" => nil,
      "_type" => "array",
      "_next" => nil,
      "_id" => "hello",
      "entries" => [
        {"_id" => "hello2", "_sig" => "nohteunth"}
      ],
      "_hash" => hash.to_s
    })
  end

  it "vm_rehash_page can calculate the hash correctly for hashes" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _head: null,
        "_type": "hash",
        _next: null,
        _id: "hello",
        entries: {
          "my_key": {_sig: "a"},
          "my_key2": {_sig: "b"},
          "my_key3": {_sig: "c"},
        }
      }

      vm_rehash_page(page);
    }

    #Calculate hash ourselves
    hash = crc32("hello")

    #XOR the _sigs for the hash calculations
    a = crc32("a", 0)
    b = crc32("b", 0)
    c = crc32("c", 0)
    hash = crc32((a + b + c).to_s, hash)

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #Expect the same hash
    expect(page).to eq({
      "_head" => nil,
      "_next" => nil,
      "_type" => "hash",
      "_id" => "hello",
      "entries" => {
        "my_key" => {"_sig" => "a"},
        "my_key2" => {"_sig" => "b"},
        "my_key3" => {"_sig" => "c"},
      },
      "_hash" => hash.to_s
    })
  end


  it "vm_rehash_page can calculate the hash correctly with head and next" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _head: "a",
        _next: "b",
        _id: "hello",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      vm_rehash_page(page);
    }

    #Calculate hash ourselves
    hash = crc32("a")
    hash = crc32("b", hash)
    hash = crc32("hello", hash)
    hash = crc32("nohteunth", hash)
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #Expect the same hash
    expect(page).to eq({
      "_head" => "a",
      "_next" => "b",
      "_id" => "hello",
      "entries" => [
        {"_id" => "hello2", "_sig" => "nohteunth"}
      ],
      "_hash" => hash.to_s
    })
  end

  it "Can call vm_cache_write and save it to vm_cache[ns][id]" do 
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      page = {
        _head: "a",
        _next: "b",
        _id: "hello",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      vm_rehash_page(page);

      //Save page
      vm_cache_write("user", page);
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
      "spec" => {
        "test" => []
      },
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

    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    vm_write_list = JSON.parse(ctx.eval("JSON.stringify(vm_write_list[0])"));
    expect(read_res_params).to eq(vm_write_list)
  end

  it "non-sync watch does send two watch callbacks to a controller if there is cached content" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller12.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);
    }

    #Should not have read anything at this point in time
    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    expect(read_res_params.length).to eq(0)

    ctx.eval("int_dispatch([])")

    #Now we read the first after it de-queued
    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    expect(read_res_params.length).to eq(1)

    ctx.eval("int_dispatch([])")

    #And now the second
    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    expect(read_res_params.length).to eq(2)

    #And they should have been read in order
    vm_write_list = JSON.parse(ctx.eval("JSON.stringify(vm_write_list)"));
    expect(read_res_params).to eq(vm_write_list)
  end

  it "vm_cache_write does not tell controllers an update has occurred if the page requested to cache was already cached" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller13.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    vm_write_list = JSON.parse(ctx.eval("JSON.stringify(vm_write_list)"));
    expect(read_res_params).to eq([vm_write_list[0]])
  end

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
        "test" => []
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

  it "Stores dirty pages written via vm_cache_write in vm_dirty" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      page = {
        _head: "a",
        _next: "b",
        _id: "hello",
        entries: [
          {_id: "hello2", _sig: "nohteunth"},
        ]
      }

      vm_rehash_page(page);

      //Save page
      vm_cache_write("user", page);
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

  it "Tries to write to disk when the pageout runs" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller18.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    @driver.ignore_up_to "if_per_set", 2
    @driver.mexpect("if_per_set", ["spec", page["_id"], page], 2)
  end

  it "Does send a read request from disk cache when watching a key for the first time" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller19.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Call pageout *now*
      vm_pageout();

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 2
    @driver.mexpect("if_per_get", ["vm", "spec", "test"], 2)
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
    }

    @driver.ignore_up_to "if_per_get", 2
    @driver.get "if_per_get", 2

    #There should not be another request for the drive
    expect {
      @driver.ignore_up_to "if_per_get"
    }.to raise_exception
  end

  it "Only sends one disk read request when multiple watches are attempted, and the first watch is sync: true" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller_sync", 1, {}, null);
      base2 = _embed("my_controller", base+2, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.get "if_per_get", 0

    #There should not be another request for the drive
    expect {
      @driver.ignore_up_to "if_per_get"
    }.to raise_exception
  end

  it "Sends two disk read request when multiple watches are attempted, and the second watch is sync: true but the disk does not read back before it is requested" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);
      base2 = _embed("my_controller_sync", base+2, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #The inner controller's on_entry is called before, so it's in reverse order
    @driver.ignore_up_to "if_per_get", 0
    @driver.get "if_per_get", 0
    @driver.ignore_up_to "if_per_get", 2
  end

  it "Sends one disk read request when multiple watches are attempted, and the second watch is sync: true and the disk *does* read back before it is requested" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb");

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    page0 = JSON.parse(ctx.eval("JSON.stringify(page0)"))
    @driver.int "int_per_get_res", ["vm", "spec", page0]

    ctx.eval %{
      base2 = _embed("my_controller_sync", base+2, {}, null);
    }

    #The inner controller's on_entry is called before, so it's in reverse order
    @driver.ignore_up_to "if_per_get", 2
    @driver.get "if_per_get", 2

    #There should not be another request for the drive
    expect {
      @driver.ignore_up_to "if_per_get"
    }.to raise_exception
  end

  it "Only sends one disk read request when multiple sync watches are attempted" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller8.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller_sync", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.ignore_up_to "if_per_get", 0
    @driver.get "if_per_get", 0

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    @driver.int "int_per_get_res", ["vm", "spec", page]

    ctx.eval %{
      base2 = _embed("my_controller_sync", base+2, {}, null);
    }

    #There should not be another request for the drive
    expect {
      @driver.ignore_up_to "if_per_get"
    }.to raise_exception
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

  it "Responds twice to watch with a missing cache but where the disk has a copy and then the pager responds" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller20.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Manually construct a page
      page = {
        _head: null,
        _next: null,
        _id: "hello",
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
    @driver.int "int_per_get_res", ["vm", "spec", page]

    #Now, we pretend that a pager has written to the cache because it has
    #received data back
    ctx.eval(%{vm_cache_write("spec", page2)})

    res = JSON.parse(ctx.eval("JSON.stringify(read_res)"))
    expect(res).to eq([
      page, page2
    ])
 end

 it "Responds once to watch with a missing cache but where the pager responds before the disk" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller20.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Manually construct a page
      page = {
        _head: null,
        _next: null,
        _id: "hello",
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
    @driver.int "int_per_get_res", ["vm", "spec", page]

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
end
