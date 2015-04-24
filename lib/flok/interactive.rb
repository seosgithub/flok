require 'therubyracer'
require 'v8'

#Interactive pipe for testing. 
#Creates a server that routes $stdin into int_dispatch and $stdout to inf_dispatch.

module Flok
  class InteractiveServer
    def initialize app_js_path
      @app_js_path = app_js_path
      @ctx = V8::Context.new
      @ctx.load app_js_path

      inject_ruby_into_js
      inject_dispatch_shims
    end

    #Will take over any remaining IO
    def begin_pipe
      loop do
        begin
          q = JSON.parse(gets)
          @ctx[:int_dispatch].call(q)
        rescue Errno::EIO
          #Can't say anything here, we don't have a pipe
        rescue V8::Error => e
          $stderr.puts "\n--------------------------------------------------" 
          $stderr.puts "V8 Boo-Boo for #{@app_js_path}"
          $stderr.puts "--------------------------------------------------\n"
          $stderr.puts e.message
          $stderr.puts "--------------------------------------------------\n" 
          exit 1
        end
      end
    end

    #JS Functions#####################################################
    def inject_ruby_into_js 
      #Output to stdout
      @ctx["write"] = lambda do |this, str|
        str.each_line do |line|
          $stdout.puts line
          $stdout.flush
        end
      end
    end

    #Make calls to if_dispatch go to $stdout, make $stdin call int_dispatch
    def inject_dispatch_shims
      @ctx.eval %{
        function if_dispatch(q) {
          write(JSON.stringify(q));
        }
      }
    end
    ##################################################################
  end
end
