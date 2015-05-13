#Compile a controller ruby file into a javascript string

require 'erb'
module Flok
  module ServicesCompiler
    #Compile a ruby file containing flok controller definitions (from the services)
    def self.compile rb_src
      #Execute code in this context, the context will hold all the information
      #that is used to then generate code
      context = ServicesCompilerContext.new
      context.instance_eval(rb_src, __FILE__, __LINE__)

      @src = ""
      services_erb = File.read File.join(File.dirname(__FILE__), "./service_compiler_templates/services.js.erb")
      services_renderer = ERB.new(services_erb)
      @src << services_renderer.result(context.get_binding)

      #puts @src

      return @src
    end
  end
end

#Compiler executes all rb code inside this context
module Flok
  class ServicesCompilerContext
    attr_accessor :services

    def initialize
      @services = []
    end

    def get_binding
      return binding
    end

    def service name, &block
      @services << Service.new(name, &block)
    end
  end

  class Service
    attr_accessor :name
    def initialize name, &block
      @name = name
      @block = block

      self.instance_eval(&block)
    end

    def get_on_init
      return @on_init
    end

    def get_on_request
      return @on_request
    end

    def on_init str
      @on_init = macro(str)
    end

    def on_request str
      @on_request = macro(str)
    end

    def macro text
      out = StringIO.new

      text.split("\n").each do |l|
        ##Request(vc_name, spot_name, context) macro
        #if l =~ /Request/
          #l.strip!
          #l.gsub!(/Request\(/, "")
          #l.gsub! /\)$/, ""
          #l.gsub! /\);$/, ""
          #o = l.split(",").map{|e| e.strip}

          #service_name = o.shift.gsub(/"/, "")
          #info = o.shift.gsub(/"/, "")
          #event_name = o.shift.gsub(/"/, "")

          #out << %{
          #}
        #else
          out.puts l
        #end
      end

      return out.string
    end
  end
end
