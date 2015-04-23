require 'json'
require 'tempfile'
require 'securerandom'

#Interactive pipe for testing.
#Creates a server that routes $stdin into if_dispatch and $stdout to int_dispatch.

class InteractiveServer
  def initialize app_js_path
    @app_js = File.read app_js_path
    inject_dispatch_shims
  end

  #Will take over any remaining IO
  def begin_pipe
    tmp = Tempfile.new(SecureRandom.hex)
    path = tmp.path
    tmp.close!
    File.write path, @app_js

    p = IO.popen "boojs #{path}"
    loop do
      q = JSON.parse(gets)
      p.puts "if_dispatch('#{q}')"
      #$stdout.flush
    end
  end

  #JS Functions#####################################################
  #Make calls to if_dispatch go to $stdout, make $stdin call int_dispatch
  def inject_dispatch_shims
    @app_js << %{
      function int_dispatch(q) {
        console.log(JSON.stringify(q))
      }
    }
  end
  ##################################################################
end
