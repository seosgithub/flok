#Anything and everything to do with view controllers (not directly UI) above the driver level
#The vm_service_spec.rb got too long

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:vm_service" do
  include Zlib
  include_context "kern"

  it "Can create a copy of pg_spec0 and pg_spec1 and receive the correct things in it's initialization" do
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller22.rb'), File.read("./spec/kern/assets/vm/config5.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    pg_spec0_init_params = JSON.parse(ctx.eval("JSON.stringify(pg_spec0_init_params)"))
    pg_spec1_init_params = JSON.parse(ctx.eval("JSON.stringify(pg_spec1_init_params)"))

    #Expect options and ns to match in config5
    expect(pg_spec0_init_params).to eq({
      "ns" => "spec0",
      "options" => {"hello" => "world"}
    })

    #Expect options and ns to match in config5
    expect(pg_spec1_init_params).to eq({
      "ns" => "spec1",
      "options" => {"foo" => "bar"}
    })
  end
end