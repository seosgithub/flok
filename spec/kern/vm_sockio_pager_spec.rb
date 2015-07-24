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

  it "Does write a page to vm_cache that **does** already exist as <unbased, nochanges> the page receives an 'update' response from the external socket.io without a changes id" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;
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
  end

  it "Does write a page to vm_cache that **does** already exist as <unbased, changes> receives an 'update' response from the external socket.io without a changes_id" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;
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
  end

  it "Does write a page to vm_cache that **does** already exist as <based<unbased, changes>, changes> receives an 'update' response from the external socket.io without a changes_id" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;
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
  end

  it "Does write a page to vm_cache that **does** already exist as <unbased, changes> receives an 'update' response from the external socket.io **with** an existing changes_id" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch2.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;
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
    @driver.int "int_event", [dump["pg_sockio0_bp"], "update", {
      page: {
        _id: "test",
        _next: nil,
        _head: nil,
        entries: [
          {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"},
          {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"}
        ],
      }, 
      changes_id: "foo"
    }]

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
    #Changes should be present in second copy
    expect(post_read_res_dump["read_res_params"][0]["__changes_id"]).not_to eq(nil)


    #Next page should be rebased ontop of the incomming page, however, since changes_id matches
    #current changes on the page, the page is just replaced (as changes were aknowledged and there
    #is nothing to repair)
    expect(post_read_res_dump["read_res_params"][1]["entries"]).to eq([
      {"_id" => "foo3", "_sig" => "foo3", "value" => "bar3"},
      {"_id" => "foo4", "_sig" => "foo4", "value" => "bar4"},
    ])
    #Changes should not be present in second copy
    expect(post_read_res_dump["read_res_params"][1]["__changes_id"]).to eq(nil)
  end

  it "Does write a page to vm_cache that **does not** already exist when the page receives an 'update' response from the external socket.io" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/watch.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //pg_sockio0 socket address & the endpoint for the event callback
      dump.pg_sockio0_bp = pg_sockio0_bp;
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
  end

  it "Does accept writes of pages that don't currently exist in cache; they go into vm_cache as-is" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_sockio/write.rb'), File.read("./spec/kern/assets/vm/pg_sockio/config.rb") 
    dump = ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.vm_cache = vm_cache;
    }

    #The vm_cache should now contain an entry for the page
    expect(dump["vm_cache"]["sockio"]["test"]).not_to eq(nil)
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
end
