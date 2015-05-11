#UI module spec handlers
Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:controller" do
  include_context "iface:driver"

  before(:each) do
    #Initialize ui sub-system (We need this because controller passes a pointer to it)
    @pipe.puts [[0, 0, "if_ui_spec_init"]].to_json
    @pipe.puts [[0, 0, "if_spec_controller_init"]].to_json
  end

  #Create a controller with the given base pointer
  def init_controller(bp)
    #Views are always bp+1, the bp points to an array with ['vc', 'main', spots...]
    #                                                        bp     bp+1  bp+n
    #Create a new view 'spec_blank' at bp+1
    @pipe.puts [[0, 4, "if_init_view", "spec_blank", {}, bp+1, ["main"]]].to_json

    #Attach that view to the root
    @pipe.puts [[0, 2, "if_attach_view", bp+1, 0]].to_json

    #Initilaize the view controller
    @pipe.puts [[0, 4, "if_controller_init", bp, bp+1, "__test__", {}]].to_json
  end

  #Send a custom event to a controller
  def send_event bp, event_name, info
    @pipe.puts [[0, 3, "if_event", bp, event_name, info]].to_json
  end

  it "Can initialize a controller and list that controller as active" do
    bp = 332
    init_controller(bp)

    #List controllers available
    @pipe.puts [[0, 0, "if_spec_controller_list"]].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "spec", [bp]], 6.seconds)
  end

  it "Does send back a message for the test controller action" do
    bp = 332
    init_controller(bp)

    #Send an action event
    to_action = "test_action"
    send_event(bp, "action", {:from => nil, :to => to_action})
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "spec", {"from" => nil, "to" => to_action}], 6.seconds)
  end

  it "Does send back a message for the test controller custom action" do
    bp = 332
    init_controller(bp)

    #Send an action event
    custom_name = SecureRandom.hex
    custom_info = {"info" => SecureRandom.hex}
    send_event(bp, custom_name, custom_info)
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "spec", {"name" => custom_name, "info" => custom_info}], 6.seconds)
  end
end
