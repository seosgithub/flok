#Spec for the transactional & diff of the vm service
Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_transaction" do
  include Zlib
  include_context "kern"

  it "Can initialize the pg_dummy0 pager" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    res = ctx.eval("pg_dummy0_spec_did_init")
    expect(res).to eq(true)
  end
end
