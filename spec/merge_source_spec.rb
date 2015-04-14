#require './lib/flok.rb'
#require 'tempfile'
#require 'securerandom'
#require 'v8'

#def ensure_tmp
  #tmp_spec_path = './spec/tmp'
  #Dir.mkdir(tmp_spec_path) unless File.exists?(tmp_spec_path)
#end

#RSpec.describe "Flok::MergeSourceSpec" do
  #it "when merging the kernel, it returns a string" do
    #str = Flok::MergeSource.merge_kernel
    #expect(str.class).to be(String)
  #end

  #it "when merging the kernel, it returns a string with length" do
    #str = Flok::MergeSource.merge_kernel
    #expect(str.length).to be > 0
  #end

  #it "when merging the kernel, the kernel files located in ./lib/js/kernel/ do merge and run without js syntax errors" do
    #str = Flok::MergeSource.merge_kernel
    #ctx = V8::Context.new
    #ctx.eval(str)

    ##It does not throw an error
  #end

  #it "merges the user generated source files from app/*.js" do
    ##Get a temporary file, delete it, but save the path
    #temp = Tempfile.new "flok-temp"
    #path = temp.path
    #temp.close
    #temp.unlink

    ##Create a new project
    #`ruby -Ilib ./bin/flok new #{path}`

    ##Add a source function to this project
    #main_js = %{
      #function call_me_maybe() {
        #return call_me_maybe_response;
      #}
    #}

    #two_js = %{
      #var call_me_maybe_response = "no_way";
    #}

    #File.write "#{path}/app/main.js", main_js
    #File.write "#{path}/app/two.js", two_js

    ##Build
    #rpath = Dir.pwd
    #Dir.chdir path do
      #`ruby -I#{rpath}/lib #{rpath}/bin/flok build`

      ##Execute
      #Dir.chdir './public' do
        #ctx = V8::Context.new
        #ctx.load "application.js"
        #res = ctx.eval("call_me_maybe()")
        #expect(res).to eq("no_way")
      #end
    #end
  #end
#end
