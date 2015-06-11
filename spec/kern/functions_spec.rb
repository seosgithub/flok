#Generic kernel functions

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:functions_spec" do
  include_context "kern"

 it "can use crc32" do
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the check
    res = ctx.eval("crc32(0, 'test')")
    expect(res).to eq(3632233996)
  end

 it "can use crc32 multiple times" do
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the check
    res = ctx.eval("crc32(crc32(0, 'test'), 'test2')")
    res2 = ctx.eval("crc32(crc32(0, 'test2'), 'test')")
    expect(res).not_to eq(res2)
  end

 it "can use gen_id" do
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the check
    res = ctx.eval("gen_id()")
    res2 = ctx.eval("gen_id()")
    reset_for_ctx

    ctx2 = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    res3 = ctx2.eval("gen_id()")
    expect(res.class).to eq(String)
    expect(res).not_to eq(res2)
    expect(res3).not_to eq(res)
  end
end
