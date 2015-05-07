#Contains helpers for getting information about the flok folders (like platforms available)

module Flok
  module Platform
    def self.list
      Dir.chdir './app/drivers' do
        #Get a list of directories, each directory is technically a platform
        dirs = Dir["*"].select{|e| File.directory?(e)}

        return dirs
      end
    end
  end

  #Alias
  def self.platforms
    return Platform.list
  end
end
