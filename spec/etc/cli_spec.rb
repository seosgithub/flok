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
  ENV['BUNDLE_GEMFILE'] = File.join(Dir.pwd, "Gemfile")
  ENV['RUBYOPT'] = ""
  res = system("bundle exec flok #{args}")
  raise "Could not execute bundle exec flok #{args.inspect}" unless res
end

#Create a new flok project named test and go into that directory
def flok_new 
  temp_dir = new_temp_dir
  Dir.chdir temp_dir do
    #This isn't done with flok() because we don't have a project yet, ergo, no Gemfile
    #But it's ok because it's *this* development version because we installed a copy of
    #it before this spec ran in before(:each)
    system("flok new test")

    Dir.chdir "test" do
      system('bundle install')
      yield
    end
  end
end

RSpec.describe "CLI" do
 before(:all) do
    #Uninstall old gems and install the current development gem
    system("rake gem:install")
  end

 it "Can be executed via bundle exec" do
    flok_new do
      flok "build"
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

  include SpecHelpers
  it "server does build project when first run" do
    platform = ENV['PLATFORM']
    flok_new do
      #Now execute the command with a set of arguments
      sh2("bundle exec flok server", /BUILD RAN/) do |inp, out|
        #The server should always trigger a build on it's first run
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
  end

  it "server does rebuild project when a file is added" do
    platform = ENV['PLATFORM']
    flok_new do
      #Now execute the command with a set of arguments
      sh2("bundle exec flok server", /BUILD RAN/) do |inp, out|
        #Get the original build
        application_user_js = File.read("products/#{platform}/application_user.js")

        #Now add a file
        File.write "./app/controllers/test2.rb", %{
          controller "my_controller" do
            action "my_action" do
              on_entry %{
              }
            end
          end
        }

        #Wait for a rebuild
        expect(out).to readline_and_equal_x_within_y_seconds("BUILD RAN", 5.seconds)

        #Get updated version
        application_user_js2 = File.read("products/#{platform}/application_user.js")

        #Make sure the compiled file is different and it's somewhat valid (length > 30)
        expect(application_user_js2).not_to eq(application_user_js)
        expect(application_user_js2.length).to be > 30 #Magic 30 to avoid any problems
      end
    end
  end

  it "server does host products on localhost:9992" do
    platform = ENV['PLATFORM']
    flok_new do
      #Now execute the command with a set of arguments
      sh2("bundle exec flok server", /BUILD RAN/) do |inp, out|
        real_application_user_js = File.read("products/#{platform}/application_user.js")

        #Grab the application_user.js file
        res = wget "http://localhost:9992/application_user.js"
        expect(res).not_to eq(nil)
        expect(res.length).not_to eq(0)
        expect(res).to eq(real_application_user_js)
      end
    end
  end

  it "server does host products on localhost:9992 and changes the products when the files change" do
    platform = ENV['PLATFORM']
    flok_new do
      #Now execute the command with a set of arguments
      sh2("bundle exec flok server", /BUILD RAN/) do |inp, out|
        #Get the original
        application_user_js = wget "http://localhost:9992/application_user.js"

        #Now add a file
        File.write "./app/controllers/test2.rb", %{
          controller "my_controller" do
            action "my_action" do
              on_entry %{
              }
            end
          end
        }
        #Wait for a rebuild
        expect(out).to readline_and_equal_x_within_y_seconds("BUILD RAN", 5.seconds)

        #Grab new version
        application_user_js2 = wget "http://localhost:9992/application_user.js"

        #Make sure the compiled file is different and it's longer
        expect(application_user_js2.length).to be > application_user_js.length
        expect(application_user_js2.length).to be > 30 #Make sure it's at least something
      end
    end
  end
end
