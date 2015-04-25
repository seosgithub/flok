require 'therubyracer'

shared_context "kern" do
  before(:each) do
    @ctx = V8::Context.new
    @ctx.load "./products/#{ENV['PLATFORM']}/application.js"
  end

  #Mock a JS function... with ruby! super cool
  def mock function_name, &block
    @ctx[function_name] = block
  end
end
