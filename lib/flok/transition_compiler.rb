#Compile a controller ruby file into a javascript string

require 'erb'
module Flok
  module TransitionCompiler
    #Compile a ruby file containing flok controller definitions (from the transition)
    def self.compile rb_src
      #Execute code in this context, the context will hold all the information
      #that is used to then generate code
      context = TransitionCompilerContext.new
      context.instance_eval(rb_src, __FILE__, __LINE__)

      @src = ""
      ctable_erb = File.read File.join(File.dirname(__FILE__), "./transition_compiler_templates/ttable.js.erb")
      ctable_renderer = ERB.new(ctable_erb)
      @src << ctable_renderer.result(context.get_binding)
      #puts @src

      return @src
    end
  end
end

#Compiler executes all rb code inside this context
module Flok
  class TransitionCompilerContext
    attr_accessor :transitions, :actions, :ons

    def initialize
      @transitions = {}

      #Hash that goes from controller's name => another hash 
      #of actions that are part of the 'from' field.
      @controller_actions = {}
    end

    def get_binding
      return binding
    end

    def transition name, &block
      t = TransitionCompilerTransition.new(name, self, &block)

      @transitions[t.controller_name] ||= {}
      @transitions[t.controller_name][t.from_action] ||= {}
      @transitions[t.controller_name][t.from_action][t.to_action] = t.info
    end
  end

  class TransitionCompilerTransition
    attr_accessor :name, :controller_name, :from_action, :to_action
    def initialize name, ctx, &block
      @name = name
      @paths = []
      @ctx = ctx

      self.instance_eval(&block)
    end

    def controller name
      @controller_name = name
    end

    def from name
      @from_action = name
    end

    def to name 
      @to_action = name
    end

    def path name, dir
    end

    def info
      return {:name => name}
    end
  end
end
