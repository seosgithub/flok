require_relative 'helpers'

module Flok
  class GotoHooksDSLEnv
    attr_accessor :selectors, :from_action_responds_to, :to_action_responds_to

    def initialize
      @selectors = []
    end

    def controller name
      @selectors << ->(p) { p["controller_name"] and p["controller_name"] == name.to_s }
    end

    #The previous / next action contains an event handler for...
    #################################################################################
    def from_action_responds_to? responds
      @from_action_responds_to = responds
      @selectors << ->(p) { p["might_respond_to"] and p["might_respond_to"].include? responds }
    end

    def to_action_responds_to? responds
      @to_action_responds_to = responds
      @selectors << ->(p) { p["might_respond_to"] and p["might_respond_to"].include? responds }
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

      #Evaluated expression to see if event should fire, the max term in POS where a bunch of
      #terms are ANDED togeather
      ands = JSTermGroup.new

      #Use the actions_responds_to to lookup qualifying actions and then check to see if we are going to/from
      #those qualifying actions
      if dsl_env.from_action_responds_to
        qualifying_from_actions = entry_hook_params["actions_responds_to"].select{|k, v| v.include? dsl_env.from_action_responds_to}.map{|k, v| k}

        #Get or terms
        ors = JSTermGroup.new
        qualifying_from_actions.each do |action_name|
          ors << "old_action === '#{action_name}'"
        end

        ands << ors.to_or_js
      end

      if dsl_env.to_action_responds_to
        qualifying_to_actions = entry_hook_params["actions_responds_to"].select{|k, v| v.include? dsl_env.to_action_responds_to}.map{|k, v| k}

        #Get or terms
        ors = JSTermGroup.new
        qualifying_to_actions.each do |action_name|
          ors << "__info__.action === '#{action_name}'"
        end

        ands << ors.to_or_js
      end

      next %{
        if (#{ands.to_and_js}) {
          SEND("main", "if_hook_event", "#{hook_event_name}", {});
        }
      }
    end
    manifest << entry
  end
end
