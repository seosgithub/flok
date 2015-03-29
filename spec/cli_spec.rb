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

  it "Creates a new module folder with correct root folders" do
    #Get a temporary file, delete it, but save the path
    temp = Tempfile.new "flok-temp"
    path = temp.path
    temp.close
    temp.unlink

    `ruby -Ilib ./bin/flok new #{path}`

    folders = %w{app lib config}

    folders.each do |f|
      p = "#{path}/#{f}"
      (Dir.exists? p).should eq(true)
    end
  end

  it "The new module has all the files and folders of a RubyGem" do
    #Get a temporary file, delete it, but save the path
    temp = Tempfile.new "flok-temp"
    path = temp.path
    temp.close
    temp.unlink
    Dir.mkdir(path)
    test_gem_path = "#{path}/test_gem"
    Dir.mkdir(test_gem_path)
    file_paths = []
    dir_paths = []
    name = "#{SecureRandom.hex[0..4]}_module_name"
    Dir.chdir(test_gem_path) do
      `bundle gem #{name}`

      Dir.chdir "./#{name}" do
        Dir["**/*"].each do |f|
          if File.file?(f)
            file_paths << f
          end

          if File.directory?(f)
            dir_paths << f
          end
        end
      end

      file_paths.uniq!
      dir_paths.uniq!
    end

    `ruby -Ilib ./bin/flok new #{path}/#{name}`
    Dir.chdir "#{path}/#{name}" do
      Dir["**/*"].each do |f|
        if File.file?(f)
          file_paths = file_paths - [f]
        end

        if File.directory?(f)
          dir_paths = dir_paths - [f]
        end
      end

      puts "------------------------------------------------------------------------------"
      puts "Files not found matching Gemfile: #{file_paths.inspect}" if file_paths.count > 0
      puts "Directories not found matching Gemfile: #{dir_paths.inspect}" if file_paths.count > 0
      puts "------------------------------------------------------------------------------"
    end

  end
end
