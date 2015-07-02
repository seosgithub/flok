#Anything and everything to do with view controllers (not directly UI) above the driver level
#The vm_service_spec.rb got too long

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_diff" do
  include Zlib
  include_context "kern"

 it "can use vm_page_diff for array with modified entry" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    expect(ctx.dump("diff_them(mod0)")).to eq([
      ["modify", {"value" => "b", "_sig" => "sig_new", "_id" => "0"}]
    ])
    expect(ctx.dump("diff_them(mod1)")).to eq([
      ["modify", {"value" => "c", "_sig" => "sig_new", "_id" => "1"}]
    ])
    expect(ctx.dump("diff_them(mod2)")).to eq([
      ["modify", {"value" => "b", "_sig" => "sig_new", "_id" => "0"}],
      ["modify", {"value" => "c", "_sig" => "sig_new", "_id" => "1"}]
    ])
  end

 it "can use vm_page_diff for array with deleted entry" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    expect(ctx.dump("diff_them(dmod0)")).to eq([
      ["delete", "0"]
    ])
    expect(ctx.dump("diff_them(dmod1)")).to eq([
      ["delete", "1"]
    ])
    expect(ctx.dump("diff_them(dmod2)")).to eq([
      ["delete", "1"], ["delete", "0"]
    ])
  end

 #Inserted is just opposite of deleted, so we flip them
 it "can use vm_page_diff for array with inserted entry" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    expect(ctx.dump("diff_them_reverse(dmod0)")).to eq([
      ["insert", {"value" => "a", "_sig" => "sig", "_id" => "0"}]
    ])
    expect(ctx.dump("diff_them_reverse(dmod1)")).to eq([
      ["insert", {"value" => "b", "_sig" => "sig", "_id" => "1"}]
    ])
    expect(ctx.dump("diff_them_reverse(dmod2)")).to eq([
      ["insert", {"value" => "a", "_sig" => "sig", "_id" => "0"}],
      ["insert", {"value" => "b", "_sig" => "sig", "_id" => "1"}]
    ])
  end

 it "can use vm_page_replay to replay 1 insert" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    #One insert (Backwards delete)
    res = ctx.eval %{
      var diff = diff_them_reverse(dmod0)
      vm_page_replay(dmod0[1], diff);
    }

    replayed_page = ctx.dump("dmod0[0]")
    original_page = ctx.dump("dmod0[1]")

    expect(original_page).to eq(replayed_page)
  end

 it "can use vm_page_replay to replay 1 modify" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    pages_src = File.read("./spec/kern/assets/vm/vm_diff_pages.js")

    #Run the checks
    ctx.eval pages_src

    #One insert (Backwards delete)
    res = ctx.eval %{
      var diff = diff_them(mod0)
      vm_page_replay(mod0[0], diff);
    }

    replayed_page = ctx.dump("mod0[0]")
    original_page = ctx.dump("mod0[1]")

    expect(original_page).to eq(replayed_page)
  end

end
