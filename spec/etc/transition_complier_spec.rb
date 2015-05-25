#Load all the test files in ./user_compiler/*.js

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './lib/flok'

#Testing the compilation of controller/action user files into javascript counterparts
RSpec.describe "Transition compiler" do
  #Return a v8 instance of a compiled js file
  def compile fn
    compiler = Flok::TransitionCompiler
    js_src(fn)
    js_res = compiler.compile(js_src(fn))
    ctx = V8::Context.new
    ctx.eval js_res
    ctx
  end

  #Get the source for a file in  ./user_compiler/*.rb
  def js_src fn
    Dir.chdir File.join(File.dirname(__FILE__), "transition_compiler") do
      return File.read(fn+'.rb')
    end
  end

  it "Can load the ruby module" do
    compiler = Flok::TransitionCompiler
  end

  it "Can compile a controller without failing" do
    ctx = compile "trans0"
  end

  it "Does have the ttable root structure with an entry for my_controller" do
    ctx = compile "trans0"
    entry = ctx.eval "ttable.my_controller"
    expect(entry).not_to eq(nil)
  end

  it "Does have the ttable root structure that can do a lookup for to" do
    ctx = compile "trans0"
    entry = ctx.eval "ttable.my_controller.index.about"
    expect(entry).not_to eq(nil)
  end

  it "Does have the ttable root structure that can do a lookup for to" do
    ctx = compile "trans0"
    entry = ctx.eval "ttable.my_controller.index.about"
    expect(entry).not_to eq(nil)
  end

  it "Does have the ttable root structure that can do a lookup for to and has a name" do
    ctx = compile "trans0"
    entry = ctx.eval "ttable.my_controller.index.about.name"
    expect(entry).not_to eq(nil)
  end
end
