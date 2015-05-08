#Compile a controller ruby file into a javascript string

require 'erb'
module Flok
  module UserCompiler
    #Compile a ruby file containing flok controller definitions (from the user)
    def self.compile rb_src
      #Execute code in this context, the context will hold all the information
      #that is used to then generate code
      context = UserCompilerContext.new
      context.instance_eval(rb_src, __FILE__, __LINE__)

      @src = ""
      ctable_erb = File.read File.join(File.dirname(__FILE__), "./user_compiler_templates/ctable.js.erb")
      ctable_renderer = ERB.new(ctable_erb)
      @src << ctable_renderer.result(context.get_binding)

      puts @src

      return @src
    end
  end
end

#Compiler executes all rb code inside this context
module Flok
  class UserCompilerContext
    attr_accessor :controllers, :actions, :ons

    def initialize
      @controllers = []
      @actions = []
      @ons = []
    end

    def get_binding
      return binding
    end

    def controller name, &block
      @controllers << UserCompilerController.new(name, self, &block)
    end

    def action controller_name, name, &block
      @actions << UserCompilerAction.new(controller_name, name, self, &block)
    end

    def on controller_name, action_name, name, &block
    end

    def actions_for_controller controller_name
      return @actions.select{|e| e.controller_name == controller_name}
    end
  end

  #Event handler inside an action
  class UserCompilerOn
    attr_accessor :controller_name, :action_name, :name
  end

  class UserCompilerAction
    attr_accessor :controller_name, :name, :on_entry_src, :ons

    def initialize controller_name, name, ctx, &block
      @controller_name = controller_name
      @name = name
      @ctx = ctx
      @ons = [] #Event handlers

      self.instance_eval(&block)
    end

    def on_entry js_src
      #returns a string
      @on_entry_src = js_src
    end

    def on name, js_src
      @ons << {:name => name, :src => js_src}
    end
  end

  class UserCompilerController
    attr_accessor :root_view, :name, :spots
    def initialize name, ctx, &block
      @name = name
      @ctx = ctx
      @spots = ['main']

      self.instance_eval(&block)
    end

    def view name
      @root_view = name
    end

    #Names of spots
    def spots *spots
      @spots += spots
    end

    #Pass through action
    def action name, &block
      @ctx.action @name, name, &block
    end
  end
end
