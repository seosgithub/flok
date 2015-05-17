require File.join(File.dirname(__FILE__), "../../../lib/flok")

module Chrome
  class BuildContext
    def initialize
      @debug = (ENV['FLOK_ENV'] == "DEBUG")
      @release = (ENV['FLOK_ENV'] == "RELEASE")
      Dir.chdir File.join(File.dirname(__FILE__), "../../../") do
        @mods = Flok::Platform.mods(ENV['PLATFORM'], ENV['FLOK_ENV'])
      end
    end

    def get_binding
      binding
    end
  end
end
