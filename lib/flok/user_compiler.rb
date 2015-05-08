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

    def action controller, name, &block
      @actions << UserCompilerAction.new(controller, name, self, &block)
    end

    def on controller_name, action_name, name, &block
    end

    def actions_for_controller controller_name
      return @actions.select{|e| e.controller.name == controller_name}
    end

    def spots_for_controller controller_name
      return @controllers.detect{|e| e.name == controller_name}.spots
    end
  end

  #Event handler inside an action
  class UserCompilerOn
    attr_accessor :controller_name, :action_name, :name
  end

  class UserCompilerAction
    attr_accessor :controller, :name, :on_entry_src, :ons

    def initialize controller, name, ctx, &block
      @controller = controller
      @name = name
      @ctx = ctx
      @ons = [] #Event handlers

      self.instance_eval(&block)
    end

    def on_entry js_src
      #returns a string
      @on_entry_src = macro(js_src)
    end

    def on name, js_src
      @ons << {:name => name, :src => macro(js_src)}
    end

    def macro js_src
      lines = js_src.split("\n").map do |line|
        
      end

      return lines.join("\n")
    end

    def macro text
      out = StringIO.new

      text.split("\n").each do |l|
        #EMBED(vc_name, spot_name, context) macro
        if l =~ /EMBED/
          l.strip!
          l.gsub!(/EMBED\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          vc_name = o.shift.gsub(/"/, "")
          spot_name = o.shift.gsub(/"/, "")
          context = o.shift.gsub(/"/, "")

          #Get the spot 
          spot_index = @controller.spots.index(spot_name)
          raise "controller #{@controller.name.inspect} attempted to embed #{spot_name.inspect} inside #{@name.inspect}, but #{spot_name.inspect} was not defined in 'spots' (#{@controller.spots.inspect})" unless spot_index

          #Calculate spot index as an offset from the base address using the index of the spot in the spots
          #address offset
          res = %{
            var ptr = _embed("#{vc_name}", __base__+#{spot_index}, {});
            __info__.embeds.push(ptr);
          }
          out.puts res
        #GOTO(action_name)
        elsif l =~ /GOTO/
          l.strip!
          l.gsub!(/GOTO\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          action_name = o.shift.gsub(/"/, "")

          #Switch the actions, reset embeds, and call on_entry
          res = %{
            __info__.action = "#{action_name}";

            //Remove all views
            var embeds = __info__.embeds;
            for (var i = 0; i < __info__.embeds.length; ++i) {
              main_q.push([1, "if_free_view", embeds[i]]);
            }

            __info__.embeds = [];
            __info__.cte.actions[__info__.action].on_entry(__base__)
          }
          out.puts res
        else
          out.puts l
        end
      end

      puts out.string

      return out.string
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
      @ctx.action self, name, &block
    end
  end
end
