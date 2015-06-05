Dir.chdir File.join File.dirname(__FILE__), '../../'
require './lib/flok'
require './spec/env/etc'

RSpec.describe "lib/services_compiler" do
  #Return a v8 instance of a compiled js file
  def compile fn
    compiler = Flok::ServicesCompiler
    js_src(fn)
    js_res = compiler.compile(js_src(fn))
    ctx = V8::Context.new
    ctx.eval js_res

    ctx
  end

  #Get the source for a file in  ./service_compiler/*.rb
  def js_src fn
    Dir.chdir File.join(File.dirname(__FILE__), "service_compiler") do
      return File.read(fn+'.rb')
    end
  end

  it "Does fail to compile a controller with a non-existant type" do
    expect { compile "service_bad_type" }.to raise_exception
  end

  it "Can call compile method and get a copy of all the functions" do
    ctx = compile "service0"

    #on_wakeup
    res = ctx.eval("test_on_wakeup")
    expect(res).not_to eq(nil)

    #on_sleep
    res = ctx.eval("test_on_sleep")
    expect(res).not_to eq(nil)

    #on_connect
    res = ctx.eval("test_on_connect");
    expect(res).not_to eq(nil)

    #on_disconnect
    res = ctx.eval("test_on_disconnect")
    expect(res).not_to eq(nil)

    #on_event
    res = ctx.eval("test_on_hello");
    expect(res).not_to eq(nil)

    #on_handle_timer_events
    res = ctx.eval("test_handle_timer_events");
    expect(res).not_to eq(nil)
  end
end
