Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/etc'
require './lib/flok'
require './spec/lib/helpers.rb'
require './spec/lib/rspec_extensions.rb'

require 'tempfile'
require 'securerandom'

#Specifications for the ./bin/flok utility

#Execute flok binary
def flok args
  #Execute
  res = system("bundle exec #{$flok_bin_path} #{args}")
  raise "Could not execute bundle exec flok #{args.inspect}" unless res
end

#Create a new flok project named test and go into that directory
def flok_new 
  temp_dir = new_temp_dir
  Dir.chdir temp_dir do
    #This isn't done with flok() because we don't have a project yet, ergo, no Gemfile
    #But it's ok because it's *this* development version because we installed a copy of
    #it before this spec ran in before(:each)
    system("#{$flok_bin_path} new test")

    Dir.chdir "test" do
      #We need to modify the gemfile to include a path to this gem project
      #so that bundler will set everything up for us as if this was a real gem
      File.write "Gemfile", %{
        #This gemfile uses this project's path
        source 'https://rubygems.org'

        gem 'flok', :path => "#{File.join(File.dirname(__FILE__), "../../")}"
      }
      yield
    end
  end
end

RSpec.describe "CLI" do
  it "Can be executed via bundle exec" do flok_new do
      flok "build"
    end
  end

  #When this sets FLOK_CONFIG, the defines is added to the project config.yml
  #to show spec_helper_defines_spec_test. This text should show up in the final
  #source code
  it "Does set the FLOK_CONFIG to the correct file based on PLATFORM" do
    flok_new do
      #Set spec_test in project configuration
      config_yml = YAML.load_file("./config/platforms/#{ENV['PLATFORM']}/config.yml")
      config_yml["DEBUG"]["defines"] = ["spec_test"]
      File.write("./config/platforms/#{ENV['PLATFORM']}/config.yml", config_yml.to_yaml)

      #Now commit a build
      flok "build"

      #Now read the application_user file, it should contain the string located in `./app/kern/spec_helper.js`
      #that will only show if the correct defines is set
      application_user = File.read("./products/#{ENV['PLATFORM']}/application_user.js")
      expect(application_user).to include("spec_helper_defines_spec_test")
    end
  end

  it "Can create a new project with correct directories" do
    flok_new do
      #Should include all entities in the project template with the exception
      #of erb extenseded entities (which will still be included, but they each
      #will not have the erb ending
      template_nodes = nil
      Dir.chdir File.join(File.dirname(__FILE__), "../../lib/flok/project_template") do
        template_nodes = Dir["**/*"].map{|e| e.gsub(/\.erb$/i, "")}
      end
      new_proj_nodes = Dir["**/*"]
      expect(new_proj_nodes.sort).to eq(template_nodes.sort)

      expect(files).to include("Gemfile")
    end
  end

  it "Can build a project with every type of platform" do
    platform = ENV['PLATFORM']
    flok_new do
      #Build a new project
      flok "build"

      #Check it's products directory
      expect(dirs).to include "products"
      Dir.chdir "products" do
        #Has a platform folder
        expect(dirs).to include platform
        Dir.chdir platform do
          #Has an application_user.js file
          expect(files).to include "application_user.js"

          #The application_user.js contains both the glob/application.js and the glob/user_compiler.js
          glob_application_js = File.read('glob/application.js')
          glob_user_compiler_js = File.read('glob/user_compiler.js')
          application_user_js = File.read('application_user.js')
          expect(application_user_js).to include(glob_application_js)
          expect(application_user_js).to include(glob_user_compiler_js)

          #Contains the same files as the kernel in the drivers directory
          expect(dirs).to include "drivers"
        end
      end
    end
  end

  it "Can build a project with a controller file for each platform" do
    #Compile and then return the length of the application_user.js file
    def compile_with_file path=nil
      #Custom controller to test source with
      controller_src = File.read(path) if path
      flok_new do
        File.write "./app/controllers/controller0.rb", controller_src if path

        #Build a new project
        flok "build"

        #Check it's products directory
        Dir.chdir "products" do
          #Has a platform folder
          Dir.chdir @platform do
            glob_application_js = File.read('glob/application.js')
            glob_user_compiler_js = File.read('glob/user_compiler.js')
            application_user_js = File.read('application_user.js')

            return application_user_js.split("\n").count
          end
        end
      end
    end

    platform = ENV['PLATFORM']
    @platform = platform
    controller_rb = File.read('./spec/etc/user_compiler/controller0.rb')

    #The file with content should be longer when compiled into the flat application_user.js
    len_with_content = compile_with_file "./spec/etc/user_compiler/controller0.rb"
    len_no_content = compile_with_file

    expect(len_no_content).to be < len_with_content
  end

  it "Can build a project with a file in ./app/controllers/**/.rb" do
    #Compile and then return the length of the application_user.js file
    def compile_with_file path=nil
      #Custom controller to test source with
      controller_src = File.read(path) if path
      flok_new do
        FileUtils.mkdir_p "./app/controllers/sub"
        File.write "./app/controllers/sub/controller0.rb", controller_src if path

        #Build a new project
        flok "build"

        #Check it's products directory
        Dir.chdir "products" do
          #Has a platform folder
          Dir.chdir @platform do
            glob_application_js = File.read('glob/application.js')
            glob_user_compiler_js = File.read('glob/user_compiler.js')
            application_user_js = File.read('application_user.js')

            return application_user_js.split("\n").count
          end
        end
      end
    end

    platform = ENV['PLATFORM']
    @platform = platform
    controller_rb = File.read('./spec/etc/user_compiler/controller0.rb')

    #The file with content should be longer when compiled into the flat application_user.js
    len_with_content = compile_with_file "./spec/etc/user_compiler/controller0.rb"
    len_no_content = compile_with_file

    expect(len_no_content).to be < len_with_content
  end

  it "Can build a project with a javascript file for each platform" do
    #Compile and then return the length of the application_user.js file
    def compile_with_file path=nil
      #Custom controller to test source with
      controller_src = File.read(path) if path
      flok_new do
        File.write "./app/scripts/data.js", controller_src if path

        #Build a new project
        flok "build"

        #Check it's products directory
        Dir.chdir "products" do
          #Has a platform folder
          Dir.chdir @platform do
            application_user_js = File.read('application_user.js')

            return application_user_js.split("\n").count
          end
        end
      end
    end

    platform = ENV['PLATFORM']
    @platform = platform
    #The file with content should be longer when compiled into the flat application_user.js
    len_with_content = compile_with_file "./spec/etc/user_compiler/data.js"
    len_no_content = compile_with_file

    expect(len_no_content).to be < len_with_content
  end

  it "Can build a project with an instantized service from the kernel ./app/kern/services folder" do
    #Compiled to config/services.rb
    def compile_with_file path=nil
      config_src = File.read(path) if path
      flok_new do
        File.write "./config/services.rb", config_src if path

        #Build a new project
        flok "build"

        #Check it's products directory
        Dir.chdir "products" do
          #Has a platform folder
          Dir.chdir @platform do
            application_user_js = File.read('application_user.js')

            return application_user_js.split("\n").count
          end
        end
      end
    end

    platform = ENV['PLATFORM']
    @platform = platform
    config_rb = File.read('./spec/etc/service_compiler/config0.rb')

    #The file with content should be longer when compiled into the flat application_user.js
    len_with_content = compile_with_file "./spec/etc/service_compiler/config0.rb"
    len_no_content = compile_with_file

    expect(len_no_content).to be < len_with_content
  end

  it "Can build a project with an instantized service from the user ./app/services folder" do
    #Compiled to config/services.rb
    def compile_with_file config_path=nil, src_path=nil
      config_src = File.read(config_path) if config_path
      src = File.read(src_path) if src_path
      flok_new do
        File.write "./config/services.rb", config_src if config_path
        File.write "./app/services/service0.rb", src if src_path 

        #Build a new project
        flok "build"

        #Check it's products directory
        Dir.chdir "products" do
          #Has a platform folder
          Dir.chdir @platform do
            application_user_js = File.read('application_user.js')

            return application_user_js.split("\n").count
          end
        end
      end
    end

    platform = ENV['PLATFORM']
    @platform = platform
    config_rb = File.read('./spec/etc/service_compiler/config1.rb')
    service_rb = File.read('./spec/etc/service_compiler/service0.rb')

    #The file with content should be longer when compiled into the flat application_user.js
    len_with_content = compile_with_file "./spec/etc/service_compiler/config1.rb", "./spec/etc/service_compiler/service0.rb"
    len_no_content = compile_with_file

    expect(len_no_content).to be < len_with_content
  end

  it "Can build a project with an instantized service from the user ./app/services folder and this has a function of the service" do
    #Compiled to config/services.rb
    def compile_with_file config_path=nil, src_path=nil
      config_src = File.read(config_path) if config_path
      src = File.read(src_path) if src_path
      flok_new do
        File.write "./config/services.rb", config_src if config_path
        File.write "./app/services/service0.rb", src if src_path 

        #Build a new project
        flok "build"

        #Check it's products directory
        Dir.chdir "products" do
          #Has a platform folder
          Dir.chdir @platform do
            application_user_js = File.read('application_user.js')

            return application_user_js
          end
        end
      end
    end

    platform = ENV['PLATFORM']
    @platform = platform
    config_rb = File.read('./spec/etc/service_compiler/config1.rb')
    service_rb = File.read('./spec/etc/service_compiler/service0.rb')

    #The file with content should be longer when compiled into the flat application_user.js
    res = compile_with_file "./spec/etc/service_compiler/config1.rb", "./spec/etc/service_compiler/service0.rb"
    expect(res).to include("function blah_on_wakeup()")
  end

  include SpecHelpers #wget
  it "server does host products on localhost:9992" do
    platform = ENV['PLATFORM']

    flok_new do
      begin
        rd, wr = IO.pipe
        @pid = fork do
          STDOUT.reopen(wr)
          STDERR.reopen(wr)
          exec("#{$flok_bin_path} server")
        end

        #Wait for server started
        $stderr.puts "Waiting for server to start..."
        $stderr.puts "="*100
        loop do
          res = rd.readline
          $stderr.puts "[flok server]: #{res}"
          break if res =~ /.*SERVER STARTED.*/
        end
        $stderr.puts "="*100

        #Grab the application_user.js file
        res = wget "http://localhost:9992/application_user.js"
        expect(res).not_to eq(nil)
        expect(res.length).not_to eq(0)
      ensure
        Process.kill :INT, @pid
      end
    end
  end

  it "server does host products on localhost:9992 and changes the products when the files change" do
    platform = ENV['PLATFORM']

    flok_new do
      #Now execute the command with a set of arguments

      begin
        rd, wr = IO.pipe
        @pid = fork do
          STDOUT.reopen(wr)
          STDERR.reopen(wr)
          exec("#{$flok_bin_path} server")
        end

        #Wait for server started
        $stderr.puts "Waiting for server to start..."
        $stderr.puts "="*100
        loop do
          res = rd.readline
          $stderr.puts "[flok server]: #{res}"
          break if res =~ /.*SERVER STARTED.*/
        end
        $stderr.puts "="*100

        #Grab the application_user.js file before making a change
        res0 = wget "http://localhost:9992/application_user.js"

        #Now add a file
        File.write "./app/controllers/test2.rb", %{
          controller "my_controller" do
            action "my_action" do
              on_entry %{
              }
            end
          end
        }

        #Grab the application_user.js after adding a change
        res1 = wget "http://localhost:9992/application_user.js"

        #They shouldn't be nil or 0 length
        expect(res0).not_to eq(nil); expect(res1).not_to eq(nil)
        expect(res0.length).not_to eq(0); expect(res1.length).not_to eq(0)
        
        #And they shouldn't be the same
        expect(res0.length).to be < res1.length
      ensure
        Process.kill :INT, @pid
      end
    end
  end
end
