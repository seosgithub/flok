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
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #URL is specified in the config
    @driver.ignore_up_to "if_sockio_init", 1
    @driver.mexpect "if_sockio_init", ["http://localhost", Integer], 1
  end
end
