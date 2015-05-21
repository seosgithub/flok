Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/lib/temp_dir'
require './lib/flok'

RSpec.describe "lib/build" do
  it "Can src_glob_r where it includes files in lower directories first, config, and init folders before other directories" do
    dir = Tempdir.new

    #Config
    dir["config/config_test.js"].puts "config_test"
    dir["config/config/config/config_test.js"].puts "config_test"
    dir["config/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.js"].puts "config_test"
    dir["config/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.js"].puts "config_test"
    #Init
    dir["init/init_test.js"].puts "init_test"
    dir["init/init/init/init_test.js"].puts "init_test"
    dir["init/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.js"].puts "init_test"
    dir["init/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.js"].puts "init_test"

    #Root
    dir["root.hello.js"].puts "root_test"
    dir["XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.hello.js"].puts "root_test"

    #Nested
    dir["nested/nested_test.js"].puts "nested_test"
    dir["nested/nested/nested_test.js"].puts "nested_test"
    dir["nested/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.hello.js"].puts "nested_test"
    dir["nested/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.hello.js"].puts "nested_test"

    #Nested
    dir["nested/0nested_test.js"].puts "nested_test"
    dir["nested/0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.hello.js"].puts "nested_test"
    dir["nested/0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.hello.js"].puts "nested_test"

    #Glob into the file out
    dir.cd do
      Flok.src_glob_r "js", ".", "out"
      out = File.read("out")
      outs = out.split("\n")
      $stderr.puts outs

      expect(outs.shift).to eq("config_test")
      expect(outs.shift).to eq("config_test")
      expect(outs.shift).to eq("config_test")
      expect(outs.shift).to eq("config_test")

      expect(outs.shift).to eq("init_test")
      expect(outs.shift).to eq("init_test")
      expect(outs.shift).to eq("init_test")
      expect(outs.shift).to eq("init_test")

      expect(outs.shift).to eq("root_test")
      expect(outs.shift).to eq("root_test")
      
      expect(outs.shift).to eq("nested_test")
      expect(outs.shift).to eq("nested_test")
      expect(outs.shift).to eq("nested_test")

      expect(outs.shift).to eq("nested_test")
      expect(outs.shift).to eq("nested_test")
      expect(outs.shift).to eq("nested_test")

    end
  end
end
