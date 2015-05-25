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

  it "Can compile a controller" do
    ctx = compile "trans0"
  end
end
