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

 it "vm_rehash_page can calculate the hash correctly" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _head: null,
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

    #Expect the same hash
    expect(page).to eq({
      "_head" => nil,
      "_next" => nil,
      "_id" => "hello",
      "entries" => [
        {"_id" => "hello2", "_sig" => "nohteunth"}
      ],
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

  it "throws an exception if multiple watches are attempted" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller16.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    expect {
      ctx.eval %{
        base = _embed("my_controller", 1, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.to raise_exception
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

  it "does send two watch callbacks to a controller if there is cached content" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller12.rb'), File.read("./spec/kern/assets/vm/config4.rb") 

    ctx.eval %{
      base = _embed("my_controller", 1, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    read_res_params = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
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
end
