module Flok
  module UserHooksGenerators
    #goto
    class Goto < UserHooksGenerator
    end
    UserHooksToManifestOrchestrator.register_hook_gen :goto, Goto
  end
end
