require './lib/flok.rb'
require 'tempfile'
require 'securerandom'

RSpec.describe "CLI" do
  it "Creates a new module folder" do
    #Get a temporary file, delete it, but save the path
    temp = Tempfile.new "flok-temp"
    path = temp.path
    temp.close
    temp.unlink

    `ruby -Ilib ./bin/flok new #{path}`

    (Dir.exists? path).should eq(true)
  end
end
