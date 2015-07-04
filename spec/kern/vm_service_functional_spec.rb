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

  it "Can create new pages" do
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
end
