#Anything and everything to do with networking above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:net_spec" do
  include_context "kern"

  it "can call get_req() and returns to the correct callback" do
    @secret = SecureRandom.hex
   
    function "test_complete" do |info|
      @info = info.to_h
    end

    #External loopback
    external_function "if_net_req" do |verb, url, params, tp_base|
      external_int "int_net_cb", tp_base, true, {"secret" => @secret}
    end
    
    puts @ctx.eval %{
      var owner = tel_reg(1)
      get_req(owner, "http://test_url", {}, function(info) {
        test_complete(info);
      });
    }

    expect(@info).to eq({"secret" => @secret})
  end

  #Careful, therubyracer has some deadlock issues
  #it "get_req() will not respond if the owner no longer exists" do
    #@secret = SecureRandom.hex
   
    #function "test_complete" do |info|
      #@info = info.to_h
    #end

    ##External loopback
    #external_function "if_net_req" do |verb, url, params, tp_base|
      #Thread.new do
        #sleep 1
        #external_int "int_net_cb", tp_base, true, {"secret" => @secret}
      #end
    #end

    #puts @ctx.eval %{
      #owner = tel_reg(1)
      #get_req(owner, "http://test_url", {}, function(info) {
        #test_complete(info);
      #});
    #}

    ##Destroy the owner
    #@ctx.eval %{
      #tel_del(owner);
    #}
    #sleep 2

    #expect(@info).to eq(nil)
  #end

  ##Guard false positive of no-owner w/ timing
  #it "get_req() will respond if the owner still exists" do
    #@secret = SecureRandom.hex
   
    #function "test_complete" do |info|
      #@info = info.to_h
    #end

    ##External loopback
    #external_function "if_net_req" do |verb, url, params, tp_base|
      #Thread.new do
        #sleep 1
        #external_int "int_net_cb", tp_base, true, {"secret" => @secret}
      #end
    #end
    
    #puts @ctx.eval %{
      #owner = tel_reg(1)
      #get_req(owner, "http://test_url", {}, function(info) {
        #test_complete(info);
      #});
    #}

    #sleep 2

    #expect(@info).to eq({"secret"=>@secret})
  #end
end
