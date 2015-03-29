require './lib/flok.rb'
require 'tempfile'
require 'securerandom'
require 'execjs'

def ensure_tmp
  tmp_spec_path = './spec/tmp'
  Dir.mkdir(tmp_spec_path) unless File.exists?(tmp_spec_path)
end

RSpec.describe "Flok::MergeSourceSpec" do
  it "when merging the kernel, it returns a string" do
    str = Flok::MergeSource.merge_kernel
    expect(str.class).to be(String)
  end

  it "when merging the kernel, it returns a string with length" do
    str = Flok::MergeSource.merge_kernel
    expect(str.length).to be > 0
  end

  it "when merging the kernel, the kernel files located in ./lib/js/kernel/ do merge and run without js syntax errors" do
    str = Flok::MergeSource.merge_kernel
    ExecJS.compile(str)
    #It does not throw an error
  end
end
