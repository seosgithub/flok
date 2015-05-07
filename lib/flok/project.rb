#Code that is relavent to the creation of user-projects and managing user-projects

module Flok
  module Project
    def self.project_template_dir
      #Directory containing erb files and regular folders
      File.join File.dirname(__FILE__), "project_template"
    end

    #Like the unix 'find' command, will list all files and include
    #relative pathnames like './app/controllers/' in an array
    def self.list
      Dir.chdir project_template_dir do
        #Get all files/folders recursiv and strip erb
        ls = raw_list.map do |e|
          rem_erb e
        end

        return ls
      end
    end

    #Keeps erb extension
    def self.raw_list
      Dir.chdir project_template_dir do
        #Get all files/folders recursiv and strip erb
        ls = Dir["**/*"].map do |e|
          e
        end

        return ls
      end
    end

    #Remove erb extension
    def self.rem_erb str
      str.gsub(/\.erb$/, "")
    end

    #Create a new user-project by coping the templates and compiling the erb files
    def self.create directory
      #Create new directory for project
      FileUtils.mkdir_p directory
      Dir.chdir directory do
        project_dir = Dir.pwd

        #Go into project_template_dir
        Dir.chdir project_template_dir do
          raw_list.each do |n|
            if File.directory?(n)
              FileUtils.mkdir_p File.join(project_dir, n)
            else
              #Render erb
              erb = ERB.new(File.read(n))
              out = erb.result
              File.write File.join(project_dir, rem_erb(n)), out
            end
          end
        end
      end
    end
  end
end
