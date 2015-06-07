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

    #Get a list of modules for a particular environment for a platform
    def self.mods environment
      #Create array that looks like a javascript array with single quotes
      mods = self.config_yml(environment)['mods']
    end

    def self.defines environment
      #Just converting an array into a hash of true values for easier lookup
      hash = {}
      defines_arr = self.config_yml(environment)['defines']
      if defines_arr
        defines_arr.each do |e|
          hash[e] = true
        end
      end

      return hash
    end

    #Get all config.yml information for a config_yml file based on FLOK_CONFIG
    def self.config_yml environment
      #Get the config.yml path
      config_yml_path = ENV['FLOK_CONFIG']
      if config_yml_path
        raise "You didn't pass a FLOK_CONFIG variable for the config.yml" unless config_yml_path
        raise "The FLOK_CONFIG given: #{config_yml_path.inspect} does not contain a file (config.yml)" unless File.exists?(config_yml_path)
      else
        $stderr.puts "Warning: You didn't specify FLOK_CONFIG, Using default config of ./app/drivers/#{ENV['PLATFORM']}/config.yml"
        config_yml_path = "./app/drivers/#{ENV['PLATFORM']}/config.yml"
      end

      driver_config = YAML.load_file(config_yml_path)
      return driver_config[environment]
    end

  end

  #Alias
  def self.platforms
    return Platform.list
  end
end
