require_relative 'helpers'

module Flok
  class GotoHooksDSLEnv
    attr_accessor :selectors

    def initialize
      @selectors = []
    end

    def controller name
      @selectors << ->(p) { p["controller_name"] and p["controller_name"] == name.to_s }
    end

    #The previous / next action contains an event handler for...
    #################################################################################
    def from_action_responds_to? responds
      @selectors << lambda do |params|
        from_action = params["from_action"]
        actions_respond_to = params["actions_responds_to"] #This is a hash that maps all actions to sensetivity lists

        #Get the sensetivity list if possible for this action (this is the list of events this action responds to)
        if actions_respond_to[from_action]
          sensetivity_list = actions_respond_to[from_action]

          #Does the sensetivity list include the event we are interested in?
          next sensetivity_list.include? responds
        end

        #The action wasn't even listed on the list, i.e. it has no sensetivity list
        next false
      end
    end

    def to_action_responds_to? responds
      @selectors << lambda do |params|
        to_action = params["to_action"]
        actions_respond_to = params["actions_responds_to"] #This is a hash that maps all actions to sensetivity lists

        #Get the sensetivity list if possible for this action (this is the list of events this action responds to)
        if actions_respond_to[to_action]
          sensetivity_list = actions_respond_to[to_action]

          #Does the sensetivity list include the event we are interested in?
          next sensetivity_list.include? responds
        end

        #The action wasn't even listed on the list, i.e. it has no sensetivity list
        next false
      end
    end
    #################################################################################
  end

  UserHooksToManifestOrchestrator.register_hook_gen :goto do |manifest, params|
    hook_event_name = params[:hook_event_name]

    #Evaluate User given DSL (params[:block]) which comes from `./confg/hooks.rb`
    #to retrieve a set of selectors which we will pass the hooks compiler
    block = params[:block]
    dsl_env = GotoHooksDSLEnv.new
    dsl_env.instance_eval(&block)

    #Inject into HOOK_ENTRY[controller_will_goto] that match the given selectors from the DSL
    #based on the hook entry static parameters
    entry = HooksManifestEntry.new("controller_will_goto", dsl_env.selectors) do |entry_hook_params|
      next %{
        SEND("main", "if_hook_event", "#{hook_event_name}", {});
      }
    end

    manifest << entry
  end
end
