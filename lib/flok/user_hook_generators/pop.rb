module Flok
  class PopHooksDSLEnv
    attr_accessor :selectors, :before_view_spider, :after_view_spider

    def initialize
      @selectors = []
      @before_view_spider = {}
      @after_view_spider = {}
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

    def from_action name
      @selectors << lambda do |params|
        from_action = params["from_action"]

        next from_action == name
      end
    end

    #################################################################################

    def before_views spider
      @before_view_spider = spider
    end

    def after_views spider
      @after_view_spider = spider
    end
  end

  UserHooksToManifestOrchestrator.register_hook_gen :pop do |manifest, params|
    hook_event_name = params[:hook_event_name]

    #Evaluate User given DSL (params[:block]) which comes from `./confg/hooks.rb`
    #to retrieve a set of selectors which we will pass the hooks compiler
    block = params[:block]
    dsl_env = PopHooksDSLEnv.new
    dsl_env.instance_eval(&block)

    ns = "_#{SecureRandom.hex[0..5]}"

    #Inject into HOOK_ENTRY[controller_will_pop] that match the given selectors from the DSL
    #based on the hook entry static parameters
    manifest << HooksManifestEntry.new("controller_will_pop", dsl_env.selectors) do |entry_hook_params|
      next %{
        var #{ns}_before_views = find_view(__base__, #{dsl_env.before_view_spider.to_json});
        __free_asap = false;
      }
    end

    manifest << HooksManifestEntry.new("controller_did_pop", dsl_env.selectors) do |entry_hook_params|
      next %{
        //The completion callback will share a pointer to the views_to_free key index
        reg_evt(views_to_free_id, hook_completion_cb);

        var #{ns}_after_views = find_view(__base__, #{dsl_env.after_view_spider.to_json});
        var #{ns}_info = {
          views: #{ns}_after_views,
          cep: views_to_free_id
        };
        for (var k in #{ns}_before_views) {
          #{ns}_info.views[k] = #{ns}_before_views[k];
        }
        SEND("main", "if_hook_event", "#{hook_event_name}", #{ns}_info);
      }
    end
  end
end
