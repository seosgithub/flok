require 'execjs'
require 'helpers'
require 'flok/build'

RSpec.describe "interrupts" do
  it "Can dynamic dispatch via int_dispatch with one function, 1 parameter" do
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["iface"]

    platforms.each do |p|
      Flok.system!("rake build_world PLATFORM=#{p}")

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      ctx.eval("int_dispatch([1, 'set_int_dispatch_spec_1', 'testA'])")

      #Expect each dispatched spec to be equal to what we passed
      specA = ctx.eval("int_dispatch_spec_a")
      expect(specA).to eq("testA")
    end
  end

  it "Can dynamic dispatch via int_dispatch with one function, 2 parameters" do
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["iface"]

    platforms.each do |p|
      Flok.system!("rake build_world PLATFORM=#{p}")

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      ctx.eval("int_dispatch([2, 'set_int_dispatch_spec_2', 'testA', 'testB'])")

      #Expect each dispatched spec to be equal to what we passed
      specA = ctx.eval("int_dispatch_spec_a")
      specB = ctx.eval("int_dispatch_spec_b")
      expect(specA).to eq("testA")
      expect(specB).to eq("testB")
    end
  end
end
