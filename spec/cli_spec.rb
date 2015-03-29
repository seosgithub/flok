require './lib/flok.rb'
require 'tempfile'
require 'securerandom'

def ensure_tmp
  tmp_spec_path = './spec/tmp'
  Dir.mkdir(tmp_spec_path) unless File.exists?(tmp_spec_path)
end

RSpec.describe "CLI" do
  it "Creates a new module folder with absolute path" do
    #Get a temporary file, delete it, but save the path
    temp = Tempfile.new "flok-temp"
    path = temp.path
    temp.close
    temp.unlink

    `ruby -Ilib ./bin/flok new #{path}`

    (Dir.exists? path).should eq(true)
  end

  it "Creates a new module folder with relative path" do
    ensure_tmp
    fn = SecureRandom.hex

    dir = "./spec/tmp/#{fn}"
    `ruby -Ilib ./bin/flok new #{dir}`
    (File.exists?(dir).should eq(true))
  end
end
