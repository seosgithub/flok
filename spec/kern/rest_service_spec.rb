#The rest service

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:rest_service" do
  include Zlib
  include_context "kern"

  it "Can use rest service" do
    ctx = flok_new_user File.read('./spec/kern/assets/rest_service/controller0.rb'), File.read("./spec/kern/assets/rest_service/config0.rb") 
    ctx.eval %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }
  end
end
