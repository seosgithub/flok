#This contains tests for the 'functions' of the vm service system

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

#Evaluates the 
def eval_and_dump str

end

RSpec.describe "kern:vm_service_functional" do
  include Zlib
  include_context "kern"

  it "Can can use vm_create_page" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    dump = ctx.evald %{
      dump.new_page = vm_create_page("my_id")
      dump.new_anon_page = vm_create_page();
    }

    expect(dump["new_page"]).to eq({
      "_head" => nil,
      "_next" => nil,
      "_id" => "my_id",
      "entries" => [],
      "__index" => {},
      "_hash" => nil,
    })

    expect(dump["new_anon_page"]["_id"]).not_to eq nil
    expect(dump["new_anon_page"]["entries"]).to eq []
  end

  #vm_rehash_page
  ###########################################################################
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
  ###########################################################################

  #vm_reindex_page
  ###########################################################################
  it "vm_reindex_page can calculate the __index correctly" do
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
          {_id: "hello3", _sig: "nohteunth2"},
        ]
      }

      vm_reindex_page(page);
    }

    #Expect the same hash
    page = ctx.dump("page")
    expect(page.keys).to include("__index")
    expect(page["__index"]).to eq({
      "hello2" => 0,
      "hello3" => 1
    })
  end
  ###########################################################################

  #vm_diff
  ###########################################################################
  it "can use vm_diff with modified entry" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    expect(ctx.dump("diff_them(mod0)")).to eq([
      ["M", "id0", {"value" => "b", "_sig" => "sig_new", "_id" => "id0"}]
    ])
    expect(ctx.dump("diff_them(mod1)")).to eq([
      ["M", "id1", {"value" => "c", "_sig" => "sig_new", "_id" => "id1"}]
    ])
    expect(ctx.dump("diff_them(mod2)")).to eq([
      ["M", "id0", {"value" => "b", "_sig" => "sig_new", "_id" => "id0"}],
      ["M", "id1", {"value" => "c", "_sig" => "sig_new", "_id" => "id1"}]
    ])
  end

  it "can use vm_diff with deleted entry" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    expect(ctx.dump("diff_them(dmod0)")).to eq([
      ["-", "id0"]
    ])
    expect(ctx.dump("diff_them(dmod1)")).to eq([
      ["-", "id1"]
    ])
    expect(ctx.dump("diff_them(dmod2)")).to eq([
      ["-", "id1"], ["-", "id0"]
    ])
  end

  #Inserted is just opposite of deleted, so we flip them
  it "can use vm_diff with inserted entry" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    expect(ctx.dump("diff_them_reverse(dmod0)")).to eq([
      ["+", "id0", {"value" => "a", "_sig" => "sig", "_id" => "id0"}]
    ])
    expect(ctx.dump("diff_them_reverse(dmod1)")).to eq([
      ["+", "id1", {"value" => "b", "_sig" => "sig", "_id" => "id1"}]
    ])
    expect(ctx.dump("diff_them_reverse(dmod2)")).to eq([
      ["+", "id0", {"value" => "a", "_sig" => "sig", "_id" => "id0"}],
      ["+", "id1", {"value" => "b", "_sig" => "sig", "_id" => "id1"}]
    ])
  end
  ###########################################################################

  #vm_diff_replay
  ###########################################################################
  it "can use vm_diff_replay to replay insert" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      /////////////////////////////////////////////
      //Insert one at beginning (revese delete)
      var diff = diff_them_reverse(dmod0)
      vm_diff_replay(dmod0[1], diff);

      //Insert one at index 1
      diff = diff_them_reverse(dmod1)
      vm_diff_replay(dmod1[1], diff);
      /////////////////////////////////////////////
    }

    #Array
    replayed_page0 = ctx.dump("dmod0[0]")
    original_page0 = ctx.dump("dmod0[1]")
    replayed_page1 = ctx.dump("dmod1[0]")
    original_page1 = ctx.dump("dmod1[1]")

    expect(original_page0).to eq(replayed_page0)
    expect(original_page1["entries"].sort_by{|e| e["value"]}).to eq(replayed_page1["entries"].sort_by{|e| e["value"]})
  end

  it "can use vm_diff_replay to replay modify" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    #One insert (Backwards delete)
    ctx.eval %{
      var diff = diff_them(mod0)
      vm_diff_replay(mod0[0], diff);
    }

    #Array
    replayed_page = ctx.dump("mod0[0]")
    original_page = ctx.dump("mod0[1]")

    expect(original_page).to eq(replayed_page)
  end

  it "can use vm_diff_replay to replay -" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    #One insert (Backwards delete)
    ctx.eval %{
      var diff = diff_them(dmod0)
      vm_diff_replay(dmod0[0], diff);
      vm_reindex_page(dmod0[0]);

      var diff = diff_them(dmod1)
      vm_diff_replay(dmod1[0], diff);
      vm_reindex_page(dmod1[0]);
    }

    #Array
    replayed_page0 = ctx.dump("dmod0[0]")
    original_page0 = ctx.dump("dmod0[1]")

    replayed_page1 = ctx.dump("dmod1[0]")
    original_page1 = ctx.dump("dmod1[1]")

    expect(original_page0).to eq(replayed_page0)
    expect(original_page1).to eq(replayed_page1)
  end

  ###########################################################################

  #vm commit helpers
  ###########################################################################
  it "can use vm_commit for older: [unbased, nochanges]" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_commit.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      older = unbased_nochanges;
      newer = page;
      vm_commit(older, newer);
    }

    #Check changes_id
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(newer["__changes_id"]).not_to eq(nil)

    #Before & After diff
    expect(newer["entries"]).not_to eq(older["entries"])
    ctx.eval %{
      vm_diff_replay(older, newer.__changes);
    }
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(newer["entries"]).to eq(older["entries"])
  end

  it "can use vm_commit for older: [unbased, changes]" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_commit.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      older = unbased_changes;
      newer = page;
      vm_commit(older, newer);
    }

    #Check changes_id & __base
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(newer["__changes_id"]).not_to eq(nil)
    expect(newer["__base"]).not_to eq(nil)
    expect(newer["__base"]).to eq(older)

    #Before & After diff
    expect(newer["entries"]).not_to eq(older["entries"])
    ctx.eval %{
      vm_diff_replay(older, newer.__changes);
    }
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(newer["entries"]).to eq(older["entries"])
  end

  it "can use vm_commit for older: [based[unbased, changes], changes]]" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_commit.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      older = based_changes;
      newer = page;
      vm_commit(older, newer);
    }

    #Check changes_id & __base
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(newer["__changes_id"]).not_to eq(older["__base"]["__changes_id"])
    expect(newer["__changes_id"]).not_to eq(older["__changes_id"])
    expect(newer["__base"]).not_to eq(nil)
    expect(newer["__base"]).to eq(older["__base"])

    #Before & After diff
    expect(newer["entries"]).not_to eq(older["entries"])
    ctx.eval %{
      vm_diff_replay(older.__base, newer.__changes);
    }
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(newer["entries"]).not_to eq(older["entries"])
    expect(newer["entries"]).to  eq(older["__base"]["entries"])
  end

  it "can use vm_rebase for newer: [unbased, nochanges]" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_commit.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      newer = unbased_nochanges;
      older = page;
      vm_rebase(newer, older);
    }

    #older should not have been modified
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(older["__changes_id"]).to eq(nil)
    expect(older["__base"]).to eq(nil)
    expect(older["__changes"]).to eq(nil)
  end

  it "can use vm_rebase for newer: [unbased, changes]" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_commit.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      newer = unbased_changes;
      older = page;
      vm_rebase(newer, older);
    }

    #Older should take __changes & __changes_id from newer.
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(older["__changes_id"]).to eq(newer["__changes_id"])
    expect(older["__changes"]).to eq(newer["__changes"])

    #Before & After diff (Each value is indexed so that its id lines up, therefore modification
    #for first element takes place, and insertion for second when going from a1 => unbased_changes
    expect(older["entries"]).not_to eq(newer["entries"])
    expect(older["entries"].map{|e| e["value"]}).to include("8")
    expect(older["entries"].map{|e| e["value"]}).to include("6")
  end
  ###########################################################################

  it "can use vm_rebase for newer: [based[unbased, changes], changes]]" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_commit.js")

    #Run the checks
    ctx.eval pages_src

    ctx.eval %{
      newer = based_changes;
      older = page;
      vm_rebase(newer, older);
    }

    #Older should take __changes & __changes_id from newer.
    older = ctx.dump("older"); newer = ctx.dump("newer")
    expect(older["__changes_id"]).to eq(newer["__changes_id"])
    expect(older["__changes"]).to eq(newer["__changes"])

    #Before & After diff (Each value is indexed so that its id lines up, therefore modification
    #for first element takes place, and insertion for second when going from a1 => unbased_changes
    expect(older["entries"]).not_to eq(newer["entries"])
    expect(older["entries"].map{|e| e["value"]}).to include("4")
  end
end
