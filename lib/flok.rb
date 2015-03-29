require "flok/version"

module Flok
  module MergeSource
    #Merge all the kernel javascript files into one string
    def self.merge_kernel
      Dir.chdir("./lib/js/kernel/") do
        js_files = Dir["*.js"]
        out = ""
        js_files.each do |js|
          out << File.read(js)
          out << "\n"
        end

        return out
      end
    end
  end
end
