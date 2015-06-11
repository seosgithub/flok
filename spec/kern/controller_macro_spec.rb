#This was created later than the controllers, so not all macros may be 
#tested in here.  Additionally, some macros may be harder to test, so 
#this contains mostly non-side-effect (functionalish) macros that do not
#make other function calls. e.g. vm page macros

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_macro_spec" do
  include_context "kern"

  #it "Can use the NewPage macro" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/new_page_c.rb')
    #ctx.eval %{
      #base = _embed("controller", 0, {}, null);
      #int_dispatch([]);
    #}

    ##Check the page variable 
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    #expect(page).to eq({
      #"_head" =>  nil,
      #"_next" =>  nil,
      #"entries" => []
    #})
  #end

  #it "Can use the CopyPage macro" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/copy_page_c.rb')
    #ctx.eval %{
      #base = _embed("controller", 0, {}, null);
      #int_dispatch([]);
    #}

    ##not_copied page is just a reference to original_page, checked for sanity
    #original_page = JSON.parse(ctx.eval("JSON.stringify(original_page)"))
    #not_copied_page = JSON.parse(ctx.eval("JSON.stringify(not_copied_page)"))
    #copied_page = JSON.parse(ctx.eval("JSON.stringify(copied_page)"))

    ##What the copied page should look like after a copy
    #copied_should_look_like = JSON.parse(original_page.to_json)
    #copied_should_look_like["_next"] = "test" #Set in controller
    #copied_should_look_like.delete "_hash"

    #expect(not_copied_page).to eq(original_page)
    #expect(copied_page).to eq(copied_should_look_like)
  #end

  #it "Can use the EntryDel macro" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/entry_del_c.rb')
    #ctx.eval %{
      #base = _embed("controller", 0, {}, null);
      #int_dispatch([]);
    #}

    ##not_copied page is just a reference to original_page, checked for sanity
    #original_page = JSON.parse(ctx.eval("JSON.stringify(original_page)"))
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #expect(page).to eq({
      #"_head" => "head",
      #"_id" => "id",
      #"_next" => "next",
      #"entries" => []
    #})

    #expect(original_page).to eq({
      #"_head" => "head",
      #"_id" => "id",
      #"_next" => "next",
      #"entries" => [{
        #"_id" => "id", "_sig" => "sig"
      #}],
      #"_hash" => "hash"
    #})
  #end

  #it "Can use the EntryInsert macro" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/entry_insert_c.rb')
    #ctx.eval %{
      #base = _embed("controller", 0, {}, null);
      #int_dispatch([]);
    #}

    ##not_copied page is just a reference to original_page, checked for sanity
    #original_page = JSON.parse(ctx.eval("JSON.stringify(original_page)"))
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #expect(page["entries"].count).to eq(3)
    #expect(page["entries"][0]["hello"]).to eq("world")
    #expect(page["entries"][2]["hello"]).to eq("world2")

    #expect(page["entries"][0]["_sig"]).not_to eq(nil)
    #expect(page["entries"][0]["_sig"]).not_to eq(page["entries"][1]["_sig"])
  #end

  it "Can use the EntryMutable macro" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/entry_mutable_c.rb')
    ctx.eval %{
      base = _embed("controller", 0, {}, null);
      int_dispatch([]);
    }

    #not_copied page is just a reference to original_page, checked for sanity
    original_page = JSON.parse(ctx.eval("JSON.stringify(original_page)"))
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    entries = page["entries"]
    original_entries = original_page["entries"]
    expect(entries[0]["hello"]).to eq("world")
    expect(entries[0]["foo"]).to eq(nil)
    expect(entries[2]["hello"]).to eq("world")
    expect(entries[2]["foo"]).to eq(nil)

    #Shared
    expect(entries[1]["foo"]).to eq("bar")
    expect(entries[1]["hello"]).to eq(nil)

    #This should remain unchanged
    expect(original_page["entries"]).to eq([
      {"_id" => "id", "_sig" => "sig"},
      {"_id" => "id2", "_sig" => "sig2", "foo" => "bar"},
      {"_id" => "id3", "_sig" => "sig3"},
    ])
  end

  #it "Can use the SetPageNext macro" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/set_page_next_c.rb')
    #ctx.eval %{
      #base = _embed("controller", 0, {}, null);
      #int_dispatch([]);
    #}

    ##not_copied page is just a reference to original_page, checked for sanity
    #original_page = JSON.parse(ctx.eval("JSON.stringify(original_page)"))
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #expect(page["_next"]).to eq("test")
  #end

  #it "Can use the SetPageHead macro" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/set_page_head_c.rb')
    #ctx.eval %{
      #base = _embed("controller", 0, {}, null);
      #int_dispatch([]);
    #}

    ##not_copied page is just a reference to original_page, checked for sanity
    #original_page = JSON.parse(ctx.eval("JSON.stringify(original_page)"))
    #page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #expect(page["_head"]).to eq("test")
  #end
end
