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
        if l =~ /Embed/
          l.strip!
          l.gsub!(/Embed\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          vc_name = o.shift.gsub(/"/, "")
          spot_name = o.shift.gsub(/"/, "")
          context = o.shift

          #Get the spot 
          spot_index = @controller.spots.index(spot_name)
          raise "controller #{@controller.name.inspect} attempted to embed #{spot_name.inspect} inside #{@name.inspect}, but #{spot_name.inspect} was not defined in 'spots' (#{@controller.spots.inspect})" unless spot_index

          #Calculate spot index as an offset from the base address using the index of the spot in the spots
          #address offset
          res = %{
            
            var ptr = _embed("#{vc_name}", __base__+#{spot_index}+1, #{context}, __base__);
            __info__.embeds[#{spot_index-1}].push(ptr);
          }
          out.puts res
        #Send(event_name, info)
        elsif l =~ /Send/
          l.strip!
          l.gsub!(/Send\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          event_name = o.shift.gsub(/"/, "")
          info = o.shift

          out << %{
           main_q.push([3, "if_event", __base__, "#{event_name}", #{info}])
          }
        #Raise(event_name, info)
        elsif l =~ /Raise/
          l.strip!
          l.gsub!(/Raise\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          event_name = o.shift
          info = o.shift

          out << %{
            int_event(__info__.event_gw, #{event_name}, #{info});
          }
        #Lower(spot_name, event_name, info)
        elsif l =~ /Lower/
          l.strip!
          l.gsub!(/Lower\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          spot_name = o.shift.gsub(/"/, "")
          event_name = o.shift
          info = o.shift

          #Get the spot 
          spot_index = @controller.spots.index(spot_name)
          raise "controller #{@controller.name.inspect} attempted to lower message to #{spot_name.inspect} inside #{@name.inspect}, but #{spot_name.inspect} was not defined in 'spots' (#{@controller.spots.inspect})" unless spot_index

          #Forward an event to the appropriate spot
          out << %{

            var vcs = __info__.embeds[#{spot_index-1}];
            for (var i = 0; i < vcs.length; ++i) {
              int_event(vcs[i], #{event_name}, #{info});
            }
          }
        #GOTO(action_name)
        elsif l =~ /Goto/
          l.strip!
          l.gsub!(/Goto\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          action_name = o.shift.gsub(/"/, "")

          #Switch the actions, reset embeds, and call on_entry
          res = %{
            var old_action = __info__.action;
            __info__.action = "#{action_name}";

            //Remove all views
            var embeds = __info__.embeds;
            for (var i = 0; i < __info__.embeds.length; ++i) {
              for (var j = 0; j < __info__.embeds[i].length; ++j) {
                //Free +1 because that will be the 'main' view
                main_q.push([1, "if_free_view", embeds[i][j]+1]);

                //Call dealloc on the controller
                tel_deref(embeds[i][j]).cte.__dealloc__(embeds[i][j]);

                <% if @debug %>
                  var vp = embeds[i][j]+1;
                  //First locate spot this view belongs to in reverse hash
                  var spot = debug_ui_view_to_spot[vp];

                  //Find it's index in the spot
                  var idx = debug_ui_spot_to_views[spot].indexOf(vp);

                  //Remove it from the spot => [view]
                  debug_ui_spot_to_views[spot].splice(idx, 1);

                  //Remove it from the reverse hash
                  delete debug_ui_view_to_spot[vp];
                <% end %>
              }
            }

            //Prep embeds array, embeds[0] refers to the spot bp+2 (bp is vc, bp+1 is main)
            __info__.embeds = [];
            for (var i = 1; i < #{@controller.spots.count}; ++i) {
              __info__.embeds.push([]);
            }

            //Call on_entry for the new action via the singleton on_entry
            //located in ctable
            __info__.cte.actions[__info__.action].on_entry(__base__)

            //Send off event for action change
            main_q.push([3, "if_event", __base__, "action", {
              from: old_action,
              to: "#{action_name}"
            }]);
          }
          out.puts res
        #Request(service_instance_name, ename, info)
        elsif l =~ /Request/
          l.strip!
          l.gsub!(/Request\(/, "")
          l.gsub! /\)$/, ""
          l.gsub! /\);$/, ""
          o = l.split(",").map{|e| e.strip}

          name = o.shift.gsub(/"/, "")
          ename = o.shift.gsub(/"/, "")
          info = o.shift.gsub(/"/, "")
          raise "You tried to Request the service #{name.inspect}, but you haven't added that to your 'services' for this controller (#{@controller.name.inspect})" unless @controller._services.include? name
          out << %{
            #{name}_on_#{ename}(__base__, #{info});
          }
        #VM Page macros
        elsif l =~ /NewPage/
          le = (l.split /NewPage/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*)\);?/

          #Get the id value the user wants, but we have to be careful
          #because if nothing is passed, then we need to set it to null
          id_var = $1.strip
          if id_var == ""
            id_var = "null"
          end

          out << %{
            #{lvar} {
              _head: null,
              _next: null,
              entries: [],
              _id: #{id_var},
            }
          }
        elsif l =~ /CopyPage/
          le = (l.split /CopyPage/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*)\);?/
          page_var = $1

          out << %{
            var __page__ = {
              _head: #{page_var}._head,
              _next: #{page_var}._next,
              _id: #{page_var}._id,
              entries: [],
            }

            //This is a shallow clone, but we own this array
            //When a mutable entry needs to be created, an entry will be cloned
            //and swappend out
            for (var i = 0; i < #{page_var}.entries.length; ++i) {
              __page__.entries.push(#{page_var}.entries[i]);
            }

            #{lvar} __page__;
          }
        elsif l =~ /EntryDel/
          le = (l.split /EntryDel/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*?),(.*)\);?/
          page_var = $1
          index_var = $2

          out << %{
            #{page_var}.entries.splice(#{index_var}, 1);
          }

        elsif l =~ /EntryInsert/
          le = (l.split /EntryInsert/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*?),(.*),(.*)\);?/
          page_var = $1
          index_var = $2
          entry_var = $3

          out << %{
            #{entry_var}._id = gen_id();
            #{entry_var}._sig = gen_id();
            #{page_var}.entries.splice(#{index_var}, 0, #{entry_var});
          }

        elsif l =~ /SetPageNext/
          le = (l.split /SetPageNext/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*?),(.*)\);?/
          page_var = $1
          value_var = $2

          out << %{
            #{page_var}._next = #{value_var};
          }

        elsif l =~ /SetPageHead/
          le = (l.split /SetPageHead/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*?),(.*)\);?/
          page_var = $1
          value_var = $2

          out << %{
            #{page_var}._head = #{value_var};
          }

        elsif l =~ /EntryMutable/
          le = (l.split /EntryMutable/)
          lvar = le[0].strip #Probably var x = 
          exp = le[1].strip

          #For CopyPage(original_page), page_var is original_page
          #This only supports variable names at this time
          exp.match /\((.*?),(.*)\);?/
          page_var = $1
          index_var = $2

          out << %{
            //Duplicate entry
            #{page_var}.entries.splice(#{index_var}, 1, JSON.parse(JSON.stringify(#{page_var}.entries[#{index_var}])));
          }
        else
          out.puts l
        end
      end

      return out.string
    end

    #You can def things in controller and use them as macros inside actions
    #But these defs. live in the UserCompilerController instance and we need
    #to delegate these calls to the controller that are not available in the action
    def method_missing method, *args, &block
      if macro = @controller.macros[method]
        #Call the macro in our context
        self.instance_eval(&macro)
      else
        raise "No macro found named: #{method}"
      end
    end
  end

  class UserCompilerController
    attr_accessor :name, :spots, :macros, :_services
    def initialize name, ctx, &block
      @name = name
      @ctx = ctx
      @spots = ['main']
      @macros = {}
      @_services = []

      self.instance_eval(&block)
    end

    #Create an action macro
    def macro name, &block
      @macros[name] = block
    end

    #Names of spots
    def spots *spots
      @spots += spots
    end

    def services *instance_names
      @_services = instance_names.map{|e| e.to_s}
    end

    #Pass through action
    def action name, &block
      @ctx.action self, name, &block
    end
  end
end
