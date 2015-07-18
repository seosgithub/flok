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
    ctx.evald %{
      //Call embed on main root view
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.pg_sockio0_bp = pg_sockio0_bp;
    }

    #URL is specified in the config
    @driver.ignore_up_to "if_sockio_init", 1
    @driver.mexpect "if_sockio_init", ["http://localhost", Integer], 1

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

  it "Does write a page to vm_cache that dosen't already exist when the page receives an 'update' response from the external socket.io" do
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
end
