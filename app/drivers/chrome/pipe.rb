require 'json'
require 'tempfile'
require 'securerandom'
require 'open3'

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

    p = Open3.popen3"boojs #{path}" do |inp, out, err, _|
      loop do
        rr, ww = select([out, err, STDIN], []); e = rr[0]
        if e == err
          $stderr.puts err.read
          exit 1
        end

        if e == STDIN
          begin
            q = gets.strip
            inp.puts "if_dispatch(JSON.parse('#{q}'))"
          rescue Errno::EIO
            #Can't say anything here, we don't have a pipe
            exit 1
          rescue NoMethodError
            exit 1
          end
        end

        if e == out
          $stdout.puts out.readline
          $stdout.flush
        end
      end
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
