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
      dump.new_array_page = vm_create_page("array", "my_id");
      dump.new_hash_page = vm_create_page("hash", "my_id");
    }

    expect(dump["new_array_page"]).to eq({
      "_head" => nil,
      "_type" => "array",
      "_next" => nil,
      "_id" => "my_id",
      "entries" => [],
      "_hash" => nil,
    })

    expect(dump["new_hash_page"]).to eq({
      "_head" => nil,
      "_type" => "hash",
      "_next" => nil,
      "_id" => "my_id",
      "entries" => {},
      "_hash" => nil,
    })
  end

  #vm_rehash_page
  ###########################################################################
  it "vm_rehash_page can calculate the hash correctly for arrays" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _head: null,
        _type: "array",
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
      "_type" => "array",
      "_next" => nil,
      "_id" => "hello",
      "entries" => [
        {"_id" => "hello2", "_sig" => "nohteunth"}
      ],
      "_hash" => hash.to_s
    })
  end

  it "vm_rehash_page can calculate the hash correctly for hashes" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _head: null,
        "_type": "hash",
        _next: null,
        _id: "hello",
        entries: {
          "my_key": {_sig: "a"},
          "my_key2": {_sig: "b"},
          "my_key3": {_sig: "c"},
        }
      }

      vm_rehash_page(page);
    }

    #Calculate hash ourselves
    hash = crc32("hello")

    #XOR the _sigs for the hash calculations
    a = crc32("a", 0)
    b = crc32("b", 0)
    c = crc32("c", 0)
    hash = crc32((a + b + c).to_s, hash)

    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))

    #Expect the same hash
    expect(page).to eq({
      "_head" => nil,
      "_next" => nil,
      "_type" => "hash",
      "_id" => "hello",
      "entries" => {
        "my_key" => {"_sig" => "a"},
        "my_key2" => {"_sig" => "b"},
        "my_key3" => {"_sig" => "c"},
      },
      "_hash" => hash.to_s
    })
  end

  it "vm_rehash_page can calculate the hash correctly with head and next for an array" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config3.rb") 

    #Run the check
    res = ctx.eval %{
      //Manually construct a page
      var page = {
        _type: "array",
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
      "_type" => "array",
      "_next" => "b",
      "_id" => "hello",
      "entries" => [
        {"_id" => "hello2", "_sig" => "nohteunth"}
      ],
      "_hash" => hash.to_s
    })
  end
  ###########################################################################
end
