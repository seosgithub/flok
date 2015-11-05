require 'json'
require 'tempfile'
require 'securerandom'
require 'open3'
$stdout.sync = true

#Interactive pipe for testing.
#Creates a server that routes $stdin into if_dispatch and $stdout to int_dispatch.

class InteractiveServer
  def initialize app_js_path
    @app_js = File.read app_js_path
    inject_dispatch_shims
  end

  #Will take over any remaining IO
  def begin_pipe
    puts "LOADED"

    _begin_pipe
  end

  def _begin_pipe
    catch(:is_restarting) do
      tmp = Tempfile.new(SecureRandom.hex)
      path = tmp.path
      tmp.close!
      File.write path, @app_js

      p = Open3.popen3 "boojs #{path}" do |inp, out, err, t|
        pid = t[:pid]
        begin
          loop do
            results = select([out, err, STDIN], [])
            if results[0].include? err
              err_msg = err.readline
              $stderr.puts err_msg
              #exit 1 unless err_msg =~ /[debug]/
            end

            if results[0].include? STDIN
              begin
                q = gets.strip

                if q == "HARD_RESTART"
                  throw :is_restarting
                elsif q == "RESTART"
                  inp.puts "$__RESTART__"

                  begin
                    #Wait for restart to respond 'ok'
                    Timeout::timeout(10) do
                      restart_res = out.readline
                      raise "Restart of phantomjs did not return '__RESTART_OK__' like expected, returned: #{restart_res.inspect}" unless restart_res == "$__RESTART_OK__\n"

                      puts "RESTART OK"
                    end
                  rescue Timeout::Error
                    raise "Restart of boojs did not happen within 5 seconds"
                  rescue EOFError
                    #Sleep for a second to let the error pipe fill up from boojs, this error
                    #will then be displayed and then we will crash
                    sleep 3
                    $stderr.puts err.read
                    raise "boojs encountered an error"
                  end

                else
                  inp.puts "if_dispatch(JSON.parse('#{q}'))"
                end
              rescue Errno::EIO
                #Can't say anything here, we don't have a pipe
                exit 1
              rescue NoMethodError
                exit 1
              end
            end

            if results[0].include? out
              res = out.readline
              $stdout.puts res
              $stdout.flush
            end
          end
        ensure
          begin
            Process.kill :INT, pid
          rescue Errno::ESRCH
          end
        end
      end
    end

    puts "RESTART OK"
    _begin_pipe
  end

  #JS Functions#####################################################
  #Make calls to if_dispatch go to $stdout, make $stdin call int_dispatch
  def inject_dispatch_shims
    @app_js << %{
      function int_dispatch(q) {
        system.stdout.writeLine(JSON.stringify(q));
      }
    }
  end
  ##################################################################
end
