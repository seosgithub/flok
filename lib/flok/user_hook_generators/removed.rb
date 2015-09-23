#The controller no longer exists

module Flok
  class RemovedHooksDSLEnv
    attr_accessor :_controller

    def initialize
      @_controller = nil
    end

    def controller name
      @_controller = name
    end

    def inspect
      return "Controller = #{@_controller}"
    end
  end

  UserHooksToManifestOrchestrator.register_hook_gen :removed do |manifest, params|
    hook_event_name = params[:hook_event_name]
    block = params[:block]

    dsl_env = GotoHooksDSLEnv.new
    dsl_env.instance_eval &block

    #Inject
    entry = HooksManifestEntry.new "#{dsl_env._controller}_will_goto", %{
      SEND("main", "if_hook_event", "#{hook_event_name}", {});
    }
    manifest << entry
  end
end
