#The pg_sockio pager

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:sockio_pager" do
  include Zlib
  include_context "kern"

  it "Can initialize the pg_sockio0 pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/nothing.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    res = ctx.eval("pg_sockio0_spec_did_init")
    expect(res).to eq(true)
  end

  it "Does throw an exception if not given a url" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/nothing.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config_no_url.rb") 

    expect {
      ctx.eval %{
        //Call embed on main root view
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);
      }
    }.to raise_error(/url/)
  end

  it "Does initialize a socketio connection" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/nothing.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.pg_sockio0_bp = pg_sockio0_bp;
    }

    #URL is specified in the config
    @driver.ignore_up_to "if_sockio_init", 0
    @driver.mexpect "if_sockio_init", ["http://localhost", Integer], 0

    #Forward the update event
    @driver.ignore_up_to "if_sockio_fwd", 1
    @driver.mexpect "if_sockio_fwd", [Integer, "update", dump["pg_sockio0_bp"]], 1
  end

  it "Does send an unwatch request via socket.io when a page is unwatched" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.int "int_event", [ @ctx.eval("base"), "unwatch", {} ]

    #Expect an unwatch request
    @driver.ignore_up_to "if_sockio_send", 1 do |e|
      e[1] == "unwatch"
    end
    unwatch_msg = @driver.get "if_sockio_send", 1
    expect(unwatch_msg[2]).to eq({"page_id" => "test"})
  end

  it "Does send a watch request via socket.io when a page is watched" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #We are sending a watch request for a page named 'test'
    @driver.ignore_up_to "if_sockio_send", 1
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1
  end

  it "Does send a watch request at periodic intervals of all pages that are currently watched and then does not send pages that have been unwatched" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch3.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Get through the first two watches triggered by the original watch
    @driver.ignore_up_to "if_sockio_send", 1
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test0"
    }], 1
    @driver.ignore_up_to "if_sockio_send", 1
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test1"
    }], 1

    #Now we wait 15 seconds
    (15*4).times { @driver.int "int_timer" }

    #Now we should have a message for the synhronization of watchlist
    @driver.ignore_up_to("if_sockio_send", 1) { |e| next e[1] == "resync" }
    resync_res = @driver.get "if_sockio_send", 1
    resync_info = resync_res[2] #Hash on end contains the actual data from the message
    expect(resync_info.keys).to include("watch_list"); #Should have a watch list

    #Check the watchlist we got, first get the hash values for the pages
    expected_watch_list = []
    expected_watch_list += ["test0", nil]
    expected_watch_list += ["test1", nil]
    expect(resync_info["watch_list"]).to eq(expected_watch_list)

    #Test 2 - Now we are changing a page, so test1 should have a hash value
    #######################################################################################################
    #Update test1, which will try to read from disk, respond with a blank page
    @driver.int "int_event", [ @ctx.eval("base"), "write_test1", {} ]
    @driver.ignore_up_to "if_per_get", 2 do |e|
      next e[2] == "test1"
    end
    @driver.int "int_per_get_res", ["vm", "sockio", "test1", nil]

    #Now we wait 15 seconds (again)
    (15*4).times { @driver.int "int_timer" }

    #Now we should have a message for the synhronization of watchlist
    @driver.ignore #it's incomplete... so
    @driver.ignore_up_to("if_sockio_send", 1) { |e| next e[1] == "resync" }
    resync_res = @driver.get "if_sockio_send", 1
    resync_info = resync_res[2] #Hash on end contains the actual data from the message
    expect(resync_info.keys).to include("watch_list"); #Should have a watch list

    #Check the watchlist we got, first get the hash values for the pages
    expected_watch_list = []
    expected_watch_list += ["test0", nil]
    expected_watch_list += ["test1", @ctx.eval("vm_cache.sockio.test1._hash")]
    expect(resync_info["watch_list"]).to eq(expected_watch_list)
    #######################################################################################################

    #Test 3 - Now we unwatch a page
    #######################################################################################################
    #Unwatch test1
    @driver.int "int_event", [ @ctx.eval("base"), "unwatch_test1", {} ]

    #Now we wait 15 seconds (again)
    (15*4).times { @driver.int "int_timer" }

    #Now we should have a message for the synhronization of watchlist
    @driver.ignore #it's incomplete... so
    @driver.ignore_up_to("if_sockio_send", 1) { |e| next e[1] == "resync" }
    resync_res = @driver.get "if_sockio_send", 1
    resync_info = resync_res[2] #Hash on end contains the actual data from the message
    expect(resync_info.keys).to include("watch_list"); #Should have a watch list

    #Check the watchlist we got, first get the hash values for the pages
    expected_watch_list = []
    expected_watch_list += ["test0", nil]
    expect(resync_info["watch_list"]).to eq(expected_watch_list)
    #######################################################################################################
  end

  it "Does write a page to vm_cache that **does** already exist as <unbased, nochanges> the page receives an 'update' response from the external socket.io without a changes id (server result should be written into cache as-is); should no longer exist in unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #sockio driver should have been signaled (which it should respond asynchronously, and presumabely, after the disk)
    @driver.ignore_up_to "if_sockio_send"
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1

    #The disk should have been signaled
    @driver.ignore_up_to "if_per_get"
    @driver.mexpect "if_per_get", ["vm", "sockio", "test"], 2


    #The disk should respond with a page
    @driver.int "int_per_get_res", ["vm", "sockio", "test", {
      "_id" => "test",
      "_next" => nil,
      "_head" => nil,
      "entries" => [
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
      ]
    }]

    #We (driver sockio) received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available (as it sends to an
    #event endpoint equal to the socket bp)
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"}
      ],
    }}]

    post_read_res_dump = ctx.evald %{
      for (var i = 0; i < 100; ++i) {
        //Drain queue (vm_cache_write defers to controller)
        int_dispatch([]);
      }

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated twice, one 
    #for the disk response and one for the pager response
    expect(post_read_res_dump["read_res_params"].length).to eq(2)
    expect(post_read_res_dump["read_res_params"][0]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
    ])
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
      {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"}
    ])

    #Should no longer be unsynced
    vm_unsynced = @ctx.dump("vm_unsynced")
      expect(vm_unsynced["sockio"]).to eq({
    })
  end

  it "Does write a page to vm_cache that **does** already exist as <unbased, changes> receives an 'update' response from the external socket.io without a changes_id. Should still be in the vm_unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #sockio driver should have been signaled (which it should respond asynchronously, and presumabely, after the disk)
    @driver.ignore_up_to "if_sockio_send"
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1

    #The disk should have been signaled
    @driver.ignore_up_to "if_per_get"
    @driver.mexpect "if_per_get", ["vm", "sockio", "test"], 2


    #The disk should respond with a page that contains changes
    @driver.int "int_per_get_res", ["vm", "sockio", "test", {
      "_id" => "test",
      "_next" => nil,
      "_head" => nil,
      "entries" => [
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
      ],
      "__changes" => [
        ["+", 0, {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"}],
        ["+", 1, {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}],
        ["-", "foo3"],
      ],
      "__changes_id" => "foo"
    }]

    #We (driver sockio) received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available (as it sends to an
    #event endpoint equal to the socket bp)
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"},
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"}
      ],
    }}]

    post_read_res_dump = ctx.evald %{
      for (var i = 0; i < 100; ++i) {
        //Drain queue (vm_cache_write defers to controller)
        int_dispatch([]);
      }

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated twice, one 
    #for the disk response and one for the pager response
    expect(post_read_res_dump["read_res_params"].length).to eq(2)
    expect(post_read_res_dump["read_res_params"][0]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
    ])

    #Next page should be rebased ontop of the incomming page, such that changes are played *over* it
    #which includes deletion of foo3
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"},
      {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
    ])

    #Should still be unsynced as it contains changes (we only removed changes on __base which is double buffered)
    vm_unsynced = @ctx.dump("vm_unsynced")
    expect(vm_unsynced["sockio"]).to eq({
      "test" => 0
    })

  end

  it "Does write a page to vm_cache that **does** already exist as <unbased, changes> receives an 'update' response from the external socket.io with a mis-matching changes_id. Should still be in the vm_unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #sockio driver should have been signaled (which it should respond asynchronously, and presumabely, after the disk)
    @driver.ignore_up_to "if_sockio_send"
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1

    #The disk should have been signaled
    @driver.ignore_up_to "if_per_get"
    @driver.mexpect "if_per_get", ["vm", "sockio", "test"], 2


    #The disk should respond with a page that contains changes
    @driver.int "int_per_get_res", ["vm", "sockio", "test", {
      "_id" => "test",
      "_next" => nil,
      "_head" => nil,
      "entries" => [
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
      ],
      "__changes" => [
        ["+", 0, {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"}],
        ["+", 1, {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}],
        ["-", "foo3"],
      ],
      "__changes_id" => "foo"
    }]

    #We (driver sockio) received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available (as it sends to an
    #event endpoint equal to the socket bp)
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"},
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"}
      ],
    }, changes_id: "foo2"}]

    post_read_res_dump = ctx.evald %{
      for (var i = 0; i < 100; ++i) {
        //Drain queue (vm_cache_write defers to controller)
        int_dispatch([]);
      }

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated twice, one 
    #for the disk response and one for the pager response
    expect(post_read_res_dump["read_res_params"].length).to eq(2)
    expect(post_read_res_dump["read_res_params"][0]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
    ])

    #Next page should be rebased ontop of the incomming page, such that changes are played *over* it
    #which includes deletion of foo3
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"},
      {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
    ])

    #Should still be unsynced as it contains changes (we only removed changes on __base which is double buffered)
    vm_unsynced = @ctx.dump("vm_unsynced")
    expect(vm_unsynced["sockio"]).to eq({
      "test" => 0
    })
  end

  it "Does write a page to vm_cache that **does** already exist as <unbased, changes> receives an 'update' response from the external socket.io with matching changes_id. Should not still be in the vm_unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #sockio driver should have been signaled (which it should respond asynchronously, and presumabely, after the disk)
    @driver.ignore_up_to "if_sockio_send"
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1

    #The disk should have been signaled
    @driver.ignore_up_to "if_per_get"
    @driver.mexpect "if_per_get", ["vm", "sockio", "test"], 2


    #The disk should respond with a page that contains changes
    @driver.int "int_per_get_res", ["vm", "sockio", "test", {
      "_id" => "test",
      "_next" => nil,
      "_head" => nil,
      "entries" => [
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
      ],
      "__changes" => [
        ["+", 0, {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"}],
        ["+", 1, {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}],
        ["-", "foo3"],
      ],
      "__changes_id" => "foo"
    }]

    #We (driver sockio) received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available (as it sends to an
    #event endpoint equal to the socket bp)
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"},
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"}
      ],
    }, changes_id: "foo"}]

    post_read_res_dump = ctx.evald %{
      for (var i = 0; i < 100; ++i) {
        //Drain queue (vm_cache_write defers to controller)
        int_dispatch([]);
      }

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated twice, one 
    #for the disk response and one for the pager response
    expect(post_read_res_dump["read_res_params"].length).to eq(2)
    expect(post_read_res_dump["read_res_params"][0]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
    ])

    #Next page should be rebased ontop of the incomming page, such that changes are played *over* it
    #which includes deletion of foo3
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
      {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"},
      {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
    ])

    #Should still be unsynced as it contains changes (we only removed changes on __base which is double buffered)
    vm_unsynced = @ctx.dump("vm_unsynced")
    expect(vm_unsynced["sockio"]).to eq({
    })
  end


  it "Does write a page to vm_cache that **does** already exist as <based<unbased, changes>, changes> receives an 'update' response from the external socket.io without a changes_id. Should still exist in vm_unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #sockio driver should have been signaled (which it should respond asynchronously, and presumabely, after the disk)
    @driver.ignore_up_to "if_sockio_send"
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1

    #The disk should have been signaled
    @driver.ignore_up_to "if_per_get"
    @driver.mexpect "if_per_get", ["vm", "sockio", "test"], 2


    #The disk should respond with a page that contains <based<nobase, changes>, changes>
    @driver.int "int_per_get_res", ["vm", "sockio", "test", {
      "_id" => "test",
      "_next" => nil,
      "_head" => nil,
      "entries" => [
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
      ],
      "__changes" => [
        ["+", 0, {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"}],
        ["+", 1, {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}],
        ["-", "foo3"],
      ],
      "__changes_id" => "foo",
      "__base" => {
        "_id" => "test",
        "_next" => nil,
        "_head" => nil,
        "entries" => [
          {"_id" => "fooX", "_sig" => "fooX", "value" => "barX"},
          {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"}
        ],
        "__changes_id" => "foo2",
        "__changes" => [
          ["-", "fooX"],
          ["+", 1, {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"}]
        ]
      }
    }]

    #We (driver sockio) received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available (as it sends to an
    #event endpoint equal to the socket bp)
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
        {"_id" => "foo5", "_sig" => "foo5", "value" => "bar5"},
        {"_id" => "fooX", "_sig" => "fooX", "value" => "barX"},
      ],
    }}]

    post_read_res_dump = ctx.evald %{
      for (var i = 0; i < 100; ++i) {
        //Drain queue (vm_cache_write defers to controller)
        int_dispatch([]);
      }

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated twice, one 
    #for the disk response and one for the pager response
    expect(post_read_res_dump["read_res_params"].length).to eq(2)
    expect(post_read_res_dump["read_res_params"][0]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
    ])

    #Next version is a double replay.  First, the server page is called the new 'base', then changes from the 
    #old base are played ontop of the server page. Then the top-level changes are recalculated based on this new page,
    #and then replayed on the server's page *again* (a linked copy where the first replayed sits at __base.
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"},
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
        {"_id" => "foo5", "_sig" => "foo5", "value" => "bar5"},
    ])

    #Should still be unsynced as it contains changes (we only removed changes on __base which is double buffered)
    vm_unsynced = @ctx.dump("vm_unsynced")
    expect(vm_unsynced["sockio"]).to eq({
      "test" => 0
    })
  end

  it "Does write a page to vm_cache that **does** already exist as [changes, based[changes, unbased]] receives an 'update' response from the external socket.io **with** an existing changes_id but keeps that page in vm_unsynced" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #sockio driver should have been signaled (which it should respond asynchronously, and presumabely, after the disk)
    @driver.ignore_up_to "if_sockio_send"
    @driver.mexpect "if_sockio_send", [Integer, "watch", {
      "page_id" => "test"
    }], 1

    #The disk should have been signaled
    @driver.ignore_up_to "if_per_get"
    @driver.mexpect "if_per_get", ["vm", "sockio", "test"], 2


    #The disk should respond with a page that contains <based<nobase, changes>, changes>
    @driver.int "int_per_get_res", ["vm", "sockio", "test", {
      "_id" => "test",
      "_next" => nil,
      "_head" => nil,
      "entries" => [
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
      ],
      "__changes" => [
        ["+", 0, {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"}],
        ["+", 1, {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}],
        ["-", "foo3"],
      ],
      "__changes_id" => "foo",
      "__base" => {
        "_id" => "test",
        "_next" => nil,
        "_head" => nil,
        "entries" => [
          {"_id" => "fooX", "_sig" => "fooX", "value" => "barX"},
          {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"}
        ],
        "__changes_id" => "foo2",
        "__changes" => [
          ["-", "fooX"],
          ["+", 1, {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"}]
        ]
      }
    }]

    #We (driver sockio) received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available (as it sends to an
    #event endpoint equal to the socket bp)
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
        {"_id" => "foo5", "_sig" => "foo5", "value" => "bar5"},
        {"_id" => "fooX", "_sig" => "fooX", "value" => "barX"},
      ],
    }, changes_id: "foo2"}]

    post_read_res_dump = ctx.evald %{
      for (var i = 0; i < 100; ++i) {
        //Drain queue (vm_cache_write defers to controller)
        int_dispatch([]);
      }

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated twice, one 
    #for the disk response and one for the pager response
    expect(post_read_res_dump["read_res_params"].length).to eq(2)
    expect(post_read_res_dump["read_res_params"][0]["entries"]).to eq([
      {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
      {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"}
    ])

    #Next version is a double replay.  First, the server page is called the new 'base', then changes from the 
    #old base are played ontop of the server page. Then the top-level changes are recalculated based on this new page,
    #and then replayed on the server's page *again* (a linked copy where the first replayed sits at __base.
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
        {"_id" => "foo1", "_sig" => "foo1", "value" => "bar1"},
        {"_id" => "foo2", "_sig" => "foo2", "value" => "bar2"},
        {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
        {"_id" => "foo5", "_sig" => "foo5", "value" => "bar5"},
        {"_id" => "fooX", "_sig" => "fooX", "value" => "barX"},
    ])

    #Should still be unsynced as it contains changes (we only removed changes on __base which is double buffered)
    vm_unsynced = @ctx.dump("vm_unsynced")
    expect(vm_unsynced["sockio"]).to eq({
      "test" => 0
    })
  end

  it "Does write a page to vm_cache that **does not** already exist when the page receives an 'update' response from the external socket.io. Should not exist in vm_unsynced anymore" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;

      //Mark page as unsynced manually
      vm_unsynced["sockio"]["test"] = 0;
    }

    #We received a watch request for a page with the id 'test'
    #Now we are imagining that the socket.io driver received back some
    #data and is now signaling to the kernel that data is available
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {page: {
      _id: "test",
      _next: nil,
      _head: nil,
      entries: [
        {"_id" => "foo", "_sig" => "foo", "value" => "bar"}
      ],
    }}]

    post_read_res_dump = ctx.evald %{
      //Drain queue (vm_cache_write defers to controller)
      int_dispatch([]);

      dump.read_res_params = read_res_params;
    }

    #The controller should have received a notification that a page was updated
    expect(post_read_res_dump["read_res_params"]["entries"]).to eq([
      {"_id" => "foo", "_sig" => "foo", "value" => "bar"}
    ])

    #Should not be in the queue anymore
    vm_unsynced = @ctx.dump("vm_unsynced")
    expect(vm_unsynced["sockio"]).to eq({
    })
  end

  it "Does accept writes of pages that don't currently exist in cache; they go into vm_cache as-is and are sent to the sockio driver" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/write.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Driver response
    @driver.int "int_per_get_res", [
      "vm",
      "sockio",
      "test",
      nil
    ]

    #The vm_cache should now contain an entry for the page
    expect(ctx.dump("vm_cache")["sockio"]["test"]).not_to eq(nil)

    @driver.ignore_up_to "if_sockio_send", 1
    res = @driver.get "if_sockio_send", 1
    expect(res[1]).to eq("write")
  end

  it "Does accept writes of pages that **do** currently exist in cache; they go into vm_cache commited" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/write2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.vm_cache = vm_cache;
    }

    #The vm_cache should now contain an entry for the page
    expect(dump["vm_cache"]["sockio"]["test"]).not_to eq(nil)

    #And that entry contains commits
    expect(dump["vm_cache"]["sockio"]["test"]["__changes"]).not_to eq(nil)
    expect(dump["vm_cache"]["sockio"]["test"]["__changes_id"]).not_to eq(nil)
  end

  it "Does write to sockio interface when a page is requested to be written with changes with a page and changes" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/write2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.vm_cache = vm_cache;
    }

    #The kernel should have signaled to the driver to send a sockio request with the changes
    @driver.ignore_up_to "if_sockio_send", 1
    res = @driver.get "if_sockio_send", 1
    expect(res[2]["page"]["_id"]).to eq("test")
    expect(res[2]["changes"]).to eq([["-", "test"]])
    expect(res[2]["changes_id"].class).to eq(String)
  end

  it "Does write to sockio interface when a page is requested to be written with changes with a page and changes (and the cached page is based)" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/write2d.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.vm_cache = vm_cache;
    }

    #The kernel should have signaled to the driver to send a sockio request with the changes
    @driver.ignore_up_to "if_sockio_send", 1
    res = @driver.get "if_sockio_send", 1
    expect(res[2]["page"]["_id"]).to eq("test")
    expect(res[2]["changes"]).to eq([])
    expect(res[2]["changes_id"]).to eq("my_changes_id")
  end


  it "Does write to sockio interface when a page is requested to be written without changes with a page: and no changes: field" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/write3.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.vm_cache = vm_cache;
    }

    #The HD should have been requested (as it's not cached and it tries to lookup)
    @driver.int "int_per_get_res", [
      "vm",
      "sockio",
      "test",
      nil
    ]

    #The kernel should have signaled to the driver to send a sockio request without the changes
    @driver.ignore_up_to "if_sockio_send", 1
    res = @driver.get "if_sockio_send", 1
    expect(res[2]["page"]["_id"]).to eq("test")
    expect(res[2]["changes"]).to eq(nil)
    expect(res[2]["changes_id"]).to eq(nil)
  end
end
