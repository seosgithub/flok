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
    res = ctx.eval("test_on_wakeup(); on_wakeup_called")
    expect(res).to eq(true)

    #on_sleep
    res = ctx.eval("test_on_sleep(); on_sleep_called")
    expect(res).to eq(true)

    #on_connect
    res = ctx.eval("test_on_connect(3); on_connect_called_bp")
    expect(res).to eq(3)

    #on_disconnect
    res = ctx.eval("test_on_disconnect(3); on_disconnect_called_bp")
    expect(res).to eq(3)

    #on_event
    ################################################################
    ctx.eval("test_on_hello(3, {hello: 'world'})")
    expect(ctx.eval("on_hello_called_bp")).to eq(3)

    #Make sure json matches
    params_res = JSON.parse(ctx.eval("on_hello_called_params"))
    expect(params_res).to eq({
      "hello" => "world"
    })
    ################################################################

    #every_event
    res = ctx.eval("test_every_5_sec(); on_every_5_sec_called")
    expect(res).to eq(true)
  end
end
