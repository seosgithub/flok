#The hooks compiler is a late-stage (see ./project.md) compiler that takes the almost-fully-compiled
#javascript source (which includes the user's javascript controllers by now) and looks for special
#comment markers for which it can inject code.
module Flok
  module HooksCompiler
    #Returns a new copy of the source transformed as described by the manifest
    def self.compile(src, manifest)
      new_src = src.split("\n").map{|e| manifest.transform_line(e) }.join("\n")

      return new_src
    end
  end

  #A hooks manifest contains all the information needed so that the hooks compiler
  #can find can change the code
  class HooksManifest
    def initialize
      @manifest_entries = []
    end

    #Returns a copy of the line with transformations if needed. For example, if a line contains
    #a hook entry point, like HOOK_ENTRY[my_event] and the manifest contains code that should
    #be inserted there, this will return the inserted code (which may then be multiple lines)
    #And will also remove the comment itself
    def transform_line line
      #Get all the matched HooksManifestEntry(s) 
      injected_code = @manifest_entries.select{|e| e.does_match? line}.map{|e| e.code}

      #If there is a match of at least one hook, remove the original line and replace it
      #with all the newly found code from the HooksManifestEntry(s)
      return injected_code.join("\n") if injected_code.count > 0

      #Else, nothing was found, keep moving along and don't transform the line
      return line
    end

    #Accepts a HooksManifestEntry which can match a line and then return some text
    #that should be apart of that line. Multiple matching manifest entries
    #is possible
    def <<(entry)
      @manifest_entries << entry
    end
  end

  #When HooksManifest goes line by line, a line is considered matching when this entry
  #retruns true for its does_match? function. You pass it a regex and the string to
  #ultimately insert into the tranformed line
  #
  #E.g. - This would match //HOOK_ENTRY[my_event]
  #>HooksManifestEntry.new "my_event", "log('hit my_event');"
  class HooksManifestEntry
    def initialize matches, code
      @matches = matches
      @code = code
    end

    def does_match? line
      line =~ /\/\/HOOK_ENTRY\[#{@matches}\]/ ? true : false
    end

    def code
      return @code
    end
  end

  #Each one of these classes are used to define some function available to users in their `./config/hooks.rb` file.
  class UserHooksGenerator
    def initialize
    end
  end

  #This converts all the user hooks into a manifest
  module UserHooksToManifestOrchestrator
    @generators = {}

    #Register a user hook generator to be available to the user in their `./config/hooks.rb`
    #The name is what is used to find the correct generator when a user uses the 
    #hook :name DSL syntax
    def self.register_hook_gen name, user_hook_gen
      @generators[name] = user_hook_gen
    end

    #Converts the `./config/hooks.rb` of the user into a HooksManifestEntry
    def self.convert_hooks_to_manifest hooks_rb
    end
  end
end

#Load all the user hook generators
Dir["./lib/flok/user_hook_generators/*"].each do |f|
  load f
end
