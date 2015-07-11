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

  #pg_dummy pager
  ######################################################################
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
  ######################################################################

  #vm_transaction functions
  ######################################################################
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
  ######################################################################

  #vm_diff events to controller at the end of transactions
  ######################################################################
  def reload_vm_transaction_diff_pages(ctx)
    pages_src = File.read("./spec/kern/assets/vm/vm_transaction_diff_pages.js")
    ctx.eval pages_src
  end

  it "does send the controller the entry_modify when an entry is modified in the page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0_diff.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    reload_vm_transaction_diff_pages(ctx)
    dump = ctx.evald %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //Write
      vm_transaction_begin();
        vm_cache_write("dummy", triangle_square_z_null);
        vm_cache_write("dummy", p_circle_null_q);
      vm_transaction_end();

      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }

      dump.entry_modify_params = entry_modify_params;
      dump.entry_move_params = entry_move_params;
      dump.entry_del_params = entry_del_params;
      dump.entry_ins_params = entry_ins_params;
    }

    expect(dump["entry_modify_params"]).to eq([
      {
        "page_id" => "default",
        "entry" => {"_id" => "id0", "_sig" => "P", "value" => "P"}
      },
      {
        "page_id" => "default",
        "entry" => {"_id" => "id1", "_sig" => "Circle", "value" => "Circle"}
      }
    ])
  end

  it "does send the controller the entry_del when an entry is deleted in the page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0_diff.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    reload_vm_transaction_diff_pages(ctx)
    dump = ctx.evald %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //Write
      vm_transaction_begin();
        vm_cache_write("dummy", triangle_null_a_m);
        vm_cache_write("dummy", triangle_square_null_null);
      vm_transaction_end();

      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }

      dump.entry_modify_params = entry_modify_params;
      dump.entry_move_params = entry_move_params;
      dump.entry_del_params = entry_del_params;
      dump.entry_ins_params = entry_ins_params;
    }

    expect(dump["entry_del_params"]).to eq([
      {
        "page_id" => "default",
        "entry_id" => "id2"
      },
      {
        "page_id" => "default",
        "entry_id" => "id3"
      },
    ])
  end

  it "does send the controller the entry_move when an entry is deleted in the page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0_diff.rb'), File.read("./spec/kern/assets/vm/pg_dummy/config.rb") 
    reload_vm_transaction_diff_pages(ctx)
    dump = ctx.evald %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      //Write
      vm_transaction_begin();
        vm_cache_write("dummy", triangle_square_z_null);
        vm_cache_write("dummy", triangle_square_z_null_moved_z_square_triangle);
      vm_transaction_end();

      for (var i = 0; i < 100; ++i) {
        int_dispatch([]);
      }

      dump.entry_modify_params = entry_modify_params;
      dump.entry_move_params = entry_move_params;
      dump.entry_del_params = entry_del_params;
      dump.entry_ins_params = entry_ins_params;
    }

    expect(dump["entry_move_params"]).to eq([
      {
        "entry_id" => "id0",
        "from_page_id" => "default",
        "to_page_id" => "default",
        "to_page_index" => 2,
      },
      {
        "entry_id" => "id1",
        "from_page_id" => "default",
        "to_page_id" => "default",
        "to_page_index" => 1,
      },
    ])
  end

  ######################################################################
end
