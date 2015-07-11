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

  it "does throw exception when vm_cache_write is called before vm_transaction_begin" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    expect {
      ctx.eval %{
        //Call embed on main root view
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);

        vm_cache_write("dummy", {});
        vm_transaction_begin();
      }
    }.to raise_exception
  end

  it "does throw exception when vm_transaction_begin is called twice in a row without a vm_transaction_end" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    expect {
      ctx.eval %{
        //Call embed on main root view
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);

        vm_transaction_begin();
        vm_transaction_begin();
      }
    }.to raise_exception
  end

  it "does throw exception when vm_transaction_end is called without a vm_transaction_begin" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    expect {
      ctx.eval %{
        //Call embed on main root view
        base = _embed("my_controller", 0, {}, null);

        //Drain queue
        int_dispatch([]);

        vm_transaction_end();
      }
    }.to raise_exception
  end


  it "does not throw exception when vm_transaction_begin is called twice in a row with a vm_transaction_end in-between" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      vm_transaction_begin();
      vm_transaction_end();
      vm_transaction_begin();
    }
  end
end
