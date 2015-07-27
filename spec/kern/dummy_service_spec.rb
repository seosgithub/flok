#The dummy service

Dir.chdir File.join File.dirname(__FILE__), '../../'
require 'zlib'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:dummy_service" do
  include Zlib
  include_context "kern"

  it "Writes to the dummy service end up in the pg_dummyN_write_vm_cache_clone array" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/pg_dummy/controller0.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.pg_dummy0_write_vm_cache_clone = pg_dummy0_write_vm_cache_clone;
    }

    #Should be empty at first
    expect(dump["pg_dummy0_write_vm_cache_clone"]).to eq([])

    @driver.int "int_event", [
      dump["base"],
      "do_write",
      {}
    ]

    #Should have gotten the write request and cloned the vm_cache
    pg_dummy0_write_vm_cache_clone = ctx.dump "pg_dummy0_write_vm_cache_clone"
    expect(pg_dummy0_write_vm_cache_clone.length).to eq(1)
    expect(pg_dummy0_write_vm_cache_clone[0]["dummy"]["lol"]["_id"]).to eq("lol")
  end
end
