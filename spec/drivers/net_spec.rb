#require 'phantomjs'
#require 'rspec/wait' 
#require 'webrick'
#require "./spec/helpers"
#require 'json'
#require 'os'

#RSpec.describe "Drivers::Net" do
  #before(:all) do
    ##Respond to kill
    #@killable = []
  #end

  #after(:all) do
    #@killable ||= []
    #@killable.each {|p| p.kill}

    ##Stopgap to kill everything
    #if OS.mac?
      #`ps -ax | grep net_spec | awk '{print $1}' | grep -v #{Process.pid} | xargs kill -9 >/dev/null 2>&1`;
      #`ps -ax | grep phantomjs| awk '{print $1}' | xargs kill -9 >/dev/null 2>&1`
    #end
  #end

 #it "can make a get request" do
    ##Build driver
    #`cd ./app/drivers/browser; rake build`

    #cr = ChromeRunner.new "./products/drivers/browser.js"

    ##Setup rspec test server
    #called = false
    #spek = Webbing.get "/" do |params|
      #called = true
      #{"hello" => "world"}.to_json
    #end
    #@killable << spek
    #cr.eval "drivers.network.request('GET', 'http://localhost:#{spek.port}', {})"
    #cr.commit

    ##Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #wait(3).for { called }.to eq(true)
  #end

  #it "can make a get request with parameters" do
    ##Build driver
    #`cd ./app/drivers/browser; rake build`

    #cr = ChromeRunner.new "./products/drivers/browser.js"

    ##Setup rspec test server
    #called = false
    #result = {}
    #spek = Webbing.get "/" do |params|
      #result = params
      #called = true
      #{"hello" => "world"}.to_json
    #end
    #@killable << spek
    #cr.eval "drivers.network.request('GET', 'http://localhost:#{spek.port}', {'a':'b'})"
    #cr.commit

    ##Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #wait(3).for { called }.to eq(true)
    #expect(result).to eq({'a' => 'b'})
  #end

  #it "can make a get and respond from callback" do
    ##Build driver
    #`cd ./app/drivers/browser; rake build`

    #cr = ChromeRunner.new "./products/drivers/browser.js"

   ##Setup rspec test server
    #@spek = Webbing.get "/" do |params|
      #{"port" => @spek2.port}.to_json
    #end

    #called = false
    #@spek2 = Webbing.get "/" do |params|
      #called = true
    #end

    #@killable << @spek
    #@killable << @spek2
    #cr.eval %{
      #drivers.network.request('GET', 'http://localhost:#{@spek.port}', {}, function(res) {
        #var port = res.port;
        #drivers.network.request('GET', 'http://localhost:'+port, {});
      #})
    #}
    #cr.commit

    ###Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #wait(3).for { called }.to eq(true)
  #end

  #it "can make a get and cancel a request that has not yet been received via callback" do
    ##Build driver
    #`cd ./app/drivers/browser; rake build`

    #cr = ChromeRunner.new "./products/drivers/browser.js"

   ##Setup rspec test server
   #called = false
   #@spek = Webbing.get "/" do |params|
     #{:port => @spek2.port}.to_json
   #end

  #@spek2 = Webbing.get "/" do |params|
    #called = true
  #end

    #@killable << @spek
    #cr.eval %{
      #socket = drivers.network.request('GET', 'http://localhost:#{@spek.port}', {}, function(res) {
        #var port = res.port;
        #drivers.network.request('GET', 'http://localhost:'+port, {});

      #});

      #drivers.network.cancel_request(socket);
    #}
    #cr.commit

    ##Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #sleep 2
    #expect(called).to eq(false)
 #end

  #it "returns an error for a non-existant resource" do
    ##Build driver
    #`cd ./app/drivers/browser; rake build`

    #cr = ChromeRunner.new "./products/drivers/browser.js"

   ##Setup rspec test server
   #@spek = Webbing.get "/" do |params|
     #{:port => @spek2.port}.to_json
   #end

   #error = nil
  #@spek2 = Webbing.get "/" do |params|
    #error = params["error"]
  #end

    #@killable << @spek
    #cr.eval %{
      #socket = drivers.network.request('GET', 'http://localhost:#{@spek.port}/404', {}, function(res, error) {
        #drivers.network.request('GET', 'http://localhost:'+#{@spek2.port}, {error: error});
      #});
    #}
    #cr.commit

    ##Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #sleep 2
    #expect(error).to eq("true")
  #end
#end
