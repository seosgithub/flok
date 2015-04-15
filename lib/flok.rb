require "flok/version"

module Flok
  module MergeSource
    #Merge all the kernel javascript files into one string
    def self.merge_kernel
      Dir.chdir(File.dirname(__FILE__)) do
        #Embed drivers
        Dir.chdir("../app/drivers/browser") do
          `rake build`
        end
        out = File.read("../products/drivers/browser.js")

        Dir.chdir("./js/kernel/") do
          js_files = Dir["*.js"]
          js_files.each do |js|
            out << File.read(js)
            out << "\n"
          end
        end

        return out
      end

    end

    def self.merge_user_app
      js_files = Dir["./app/*.js"]
      out = ""
      js_files.each do |js|
        out << File.read(js)
        out << "\n"
      end

      return out
    end

    def self.merge_all
      str_kernel = self.merge_kernel
      str_user = self.merge_user_app

      return str_kernel + "\n" + str_user
    end
  end
end
