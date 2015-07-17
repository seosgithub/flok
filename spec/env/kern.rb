require './spec/env/global.rb'
require 'therubyracer'
require './spec/lib/temp_dir'

shared_context "kern" do
  before(:each) do
    reset_for_ctx
  end

  def reset_for_ctx
    res=system('rake build:world')
    raise "Could not run build:world" unless res
    @ctx = V8::Context.new
    @ctx.load "./products/#{ENV['PLATFORM']}/application.js"

    if ENV['RUBY_PLATFORM'] =~ /darwin/
      `killall phantomjs`
      `killall rspec`
    end
  end

  class V8::Context
    def dump variable
      json_res = self.eval %{
        JSON.stringify(#{variable});
      }

      return JSON.parse(json_res)
    end

    #Will return everything put into the 'dump' dictionary (pre-defined for your convenience)
    def evald str
      self.eval "dump = {}"
      self.eval str
      _dump = self.dump("dump")

      return DumpHelper.new(_dump)
    end
  end

  class DumpHelper
    def initialize dump
      @dump = dump
    end

    def [](index)
      return @dump[index]
    end
  end

  #Execute flok binary with a command
  def flok args
    #Get path to the flok binary relative to this file
    bin_path = File.join(File.dirname(__FILE__), "../../bin/flok")

    #Now execute the command with a set of arguments
    return system("#{bin_path} #{args}")
  end

  #Create a new flok project, add the given user_file (an .rb file containing controllers, etc.)
  #and then retrieve a V8 instance from this project's application_user.js
  def flok_new_user user_controllers_src, service_config=nil, service_src=nil
    temp_dir = new_temp_dir
    Dir.chdir temp_dir do
      flok "new test"
      Dir.chdir "test" do
        #Put controllers in
        File.write './app/controllers/user_controller.rb', user_controllers_src
        File.write './config/services.rb', service_config if service_config
        File.write './app/services/service0.rb', service_src if service_src

        #Build
        unless flok "build" #Will generate drivers/ but we will ignore that
          raise "Build failed"
        end

        #Execute
        @driver = FakeDriverContext.new
        v8 = V8::Context.new(:with => @driver)
        @ctx = v8
        @driver.ctx = v8
        v8.eval %{
          //We must convert this to JSON because the fake driver will receive
          //a raw v8 object otherwise
          function if_dispatch(q) {
            if_dispatch_json(JSON.stringify(q));
          }
        }
        v8.eval File.read('./products/chrome/application_user.js')
        return v8
      end
    end
  end

  #This supports if_dispatch interface and allows for sending information back via 
  #int_dispatch to the kernel. It is embededd into the v8 context environment
  class FakeDriverContext
    include RSpec::Matchers 

    attr_accessor :ctx
    def initialize
      @q = []  #Full queue, 2 dimensional all priority 
      @cq = nil #Contains only the current working priority
      @cp = nil #Contains the current priority
    end

    def if_dispatch_json q
      @q += JSON.parse(q)
    end

    #When you're running these unit tests, you may need to log, but you will
    #need to remove any _log statements before running other tests!
    def log(msg)
      $stderr.puts "v8: #{msg}"
    end

    #Expect a certain message, with some arguments, and a certain priority
    #expect("if_init_view", ["test_view", {}]) === [[0, 4, "if_init_view", "test_view", {}]]
    def mexpect(msg_name, msg_args, priority=0)
      #Dequeue from multi-priority queue if possible
      if @cq.nil? or @cq.count == 0
        @cq = @q.shift
        @cp = @cq.shift #save priority
      end

      #Make sure we got something from the priority queue
      raise "Expected #{msg_name.inspect} but there was no messages available" unless @cq

      #Now read the queue with the correct num of args
      arg_len = @cq.shift
      name = @cq.shift
      args = @cq.shift(arg_len)

      msg_args.each_with_index do |e, i|
        if e == Integer
          msg_args[i] = args[i];
        end
      end

      expect(name).to eq(msg_name), "name: #{name.inspect} of message received did not match #{msg_name.inspect}, args where #{args.inspect}"
      expect(args).to eq(msg_args)
      expect(priority).to eq(@cp)

      return args
    end

    #Ignore all messages until this one is received, then keep that one in the queue
    #There may be a lot going on and you're only interested in a part.
    #If priority is nil, it won't matter what the priority is, useful for checking exceptions
    #for non-existant messages
    def ignore_up_to msg_name, priority=nil, &block
      @did_get = []

      loop do
        if @q.count == 0 and @cq.count == 0
          raise "Waited for the message #{msg_name.inspect} but never got it... did get: \n * #{@did_get.join("\n * ")}"
        end
        #Dequeue from multi-priority queue if possible
        if @cq.nil? or @cq.count == 0
          @cq = @q.shift
          @cp = @cq.shift #save priority
        end

        #Check to see if it's the correct item
        arg_len = @cq.shift
        name = @cq.shift
        if arg_len.class == String
          $stderr.puts "Arg len is: #{arg_len.inspect}"
          $stderr.puts "Name is #{name.inspect}"
        end
        args = @cq.shift(arg_len)

        @did_get << name

        if name == msg_name
          if priority
            raise "Found the message #{msg_name.inspect} while calling ignore_up_to... but it's the wrong priority: #{@cp}, should be #{priority}" if @cp != priority
          end

          if block
            next unless block.call(args)
          end

          #Unshift everything in reverse order, we are only peeking here...
          args.reverse.each do |a|
            @cq.unshift a
          end
          @cq.unshift name
          @cq.unshift arg_len
          break
        end
      end
    end

    #Expect the queue to not contain a message matching
    def expect_not_to_contain msg_name, &block
      original_q = JSON.parse(@q.to_json)
      @cq = []

      loop do
        if @q.count == 0 and @cq.count == 0
          #Good
          @q = original_q
          @cq = nil
          return
        end
        #Dequeue from multi-priority queue if possible
        if @cq.nil? or @cq.count == 0
          @cq = @q.shift
          @cp = @cq.shift #save priority
        end

        #Check to see if it's the correct item
        arg_len = @cq.shift
        name = @cq.shift
        if arg_len.class == String
          $stderr.puts "Arg len is: #{arg_len.inspect}"
          $stderr.puts "Name is #{name.inspect}"
        end
        args = @cq.shift(arg_len)

        #Matches message name
        if name == msg_name
          #Optional test block
          if block
            next unless block.call(args)
          end

          #Uh oh, we found one!
          block_info = block ? " You gave a block to filter... check the code to see what it's checking for, it's more than just the message name" : ""
          raise "Expected not to find a message matching #{msg_name.inspect} in the queue, but found one!#{block_info}"
        end
      end
    end

    #Retrieve a message, we at least expect a name and priority
    def get msg_name, priority=0
      #Dequeue from multi-priority queue if possible
      if @cq.nil? or @cq.count == 0
        @cq = @q.shift
        @cp = @cq.shift #save priority
      end

      #Make sure we got something from the priority queue
      raise "Expected #{msg_name.inspect} but there was no messages available" unless @cq

      #Now read the queue with the correct num of args
      arg_len = @cq.shift
      name = @cq.shift
      args = @cq.shift(arg_len)

      expect(name).to eq(msg_name)
      expect(priority).to eq(@cp)

      return args
    end

    #Send a message back to flok, will drain queue as well (run flok code)
    def int msg_name, args=nil
      if args
        msg = [args.length, msg_name, *args].to_json
      else
        msg = [0, msg_name].to_json
      end
        @ctx.eval %{
          int_dispatch(#{msg});
        }
    end

    def dump_q
      q = @q
      @q = []
      return q
    end
  end
end
