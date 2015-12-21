require_relative './macro.rb'
#The hooks compiler is a late-stage (see ./project.md) compiler that takes the almost-fully-compiled
#javascript source (which includes the user's javascript controllers by now) and looks for special
#comment markers for which it can inject code.
module Flok
  module HooksCompiler
    #Returns a new copy of the source transformed as described by the manifest
    def self.compile(src, manifest)
      puts "a0"
      new_src = src.split("\n").map{|e| manifest.transform_line(e) }.join("\n")

      #Re-process macros
      puts "a1"
      new_src = Flok.macro_process new_src


      puts "a2"
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
      puts "a3"
      #Get all the matched HooksManifestEntry(s) 
      injected_code = @manifest_entries.select{|e| e.does_match? line}.map{|e| e.code_for_line(line)}

      puts "an"
      #If there is a match of at least one hook, remove the original line and replace it
      #with all the newly found code from the HooksManifestEntry(s)
      return injected_code.join("\n") if injected_code.count > 0

      puts "a4"
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
  #retruns true for its does_match? function. You pass it a name, optional parameter
  #query and the block to call when the code should be generated for a match. The block
  #receives a full copy of the parameters for the hook entry (the static ones). The 
  #param query is a lambda that also receives the block and it should return (next) true/false
  #when a match is considered true. If name is just "*" (string, not symbol), then it matches
  #all names. Passing multiple param_queries in is allowed, you just pass in multiple arrays.
  #All of the procs passed must be true for the result to be true
  #
  #E.g. - This would match //HOOK_ENTRY[my_event]
  #>HooksManifestEntry.new("my_event", ->(p){p["actions"].include? "x"}) do |hook_info|
  #  return "console.log(info = #{info["actions"]});"
  #end
  class HooksManifestEntry
    def initialize name, param_queries=->(p){true}, &block
      #If an array is not passed, make it an array with one element
      param_queries = [param_queries] if param_queries.class != Array

      @name = name.to_s
      @param_queries = param_queries
      @block = block
    end

    def does_match? line
      #Unless the matching name is a *, check to see if the hook name matches
      unless @name == "*"
        return false unless line =~ /\/\/HOOK_ENTRY\[#{@name}\]/
      end

      #Now verify with the lambda
      return @param_queries.reduce(true){|r, e| r &&= e.call(hook_entry_info_from_line(line))}
    end

    def code_for_line line
      return @block.call(hook_entry_info_from_line(line))
    end

    #Each hook entry contains a JSON encoded set of static parameters
    #for things like the controller name, etc. See docs for a list of 
    #parameters as it depends on the hook entry
    def hook_entry_info_from_line line
      json_info = line.split(/\/\/HOOK_ENTRY\[.*?\]/).last.strip 
      begin
        return JSON.parse(json_info)
      rescue => e
        raise "Couldn't parse the hooks entry JSON information, got #{json_info.inspect}: #{e.inspect}"
      end
    end
  end

  #This converts all the user hooks into a manifest
  module UserHooksToManifestOrchestrator
    $generators = {}

    #Register a user hook generator to be available to the user in their `./config/hooks.rb`
    #The name is what is used to find the correct generator when a user uses the 
    #hook :name DSL syntax
    def self.register_hook_gen name, &gen_block
      $generators[name] = gen_block
    end

    #Converts the `./config/hooks.rb` of the user into a HooksManifestEntry
    def self.convert_hooks_to_manifest hooks_rb
      #Create a new manifest, this will be passed to each generator instance
      #along with a set of parameters. Each generator will update the 
      #hooks manifest
      manifest = HooksManifest.new

      #Evaluate the user hooks DSL which will create a listing of all the
      #user's requests in the accessible :hooks_requests member of the dsl environment
      hooks_dsl_env = UserHooksDSL.new
      hooks_dsl_env.instance_eval hooks_rb

      #For each user request, lookup the appropriate generator handler and then
      #call the generator
      hook_requests = hooks_dsl_env.hook_requests
      hook_requests.each do |gen_name, requests|
        generator = $generators[gen_name]
        raise "A hook request requested the generator by the name #{gen_name.inspect} but this was not a generator..." unless generator

        requests.each do |r|
          generator.call(manifest, r)
        end
      end

      return manifest
    end

    #Interpret `./config/hooks.rb` to call the associated registered hook gen block
    class UserHooksDSL
      attr_accessor :hook_requests
      def initialize
        #Each user hook call adds a request to this hash
        #which is then processed by each matching hook generator 
        @hook_requests = {}
      end

      #Install a hook.  Leads to eventually calling the relavent hook generator. The anmes argument
      #takes one key-value pair e.g. {:goto => :settings_changed}, this would mean the hook generator
      #named 'goto' and it should create a hook event called 'settings_changed'. The block
      #is then passed on to each hook generator. See the docs on hooks.md for information on what
      #each block function takes
      def hook names, &block

        #The names parameter 
        key = names.keys.first
        hook_event_name = names.values.first
        raise "You didn't supply a hook generator name or the event name... Got #{key.inspect} and #{hook_event_name.inspect}.  e.g. hook :goto => :changed, {...}" unless key and hook_event_name

        @hook_requests[key] ||= []
        @hook_requests[key] << {
          :hook_event_name => hook_event_name,
          :block => block
        }
      end
    end
  end
end

#Load all the user hook generators
Dir.chdir File.join(File.dirname(__FILE__), "../../") do
  Dir["./lib/flok/user_hook_generators/*"].each do |f|
    load f
  end
end
