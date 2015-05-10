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

  it "Can initialize a controller and list that controller as active" do
    #Create a new view 'spec_blank' at 333
    @pipe.puts [[0, 4, "if_init_view", "spec_blank", {}, 333, ["main"]]].to_json

    #Attach that view to the root
    @pipe.puts [[0, 2, "if_attach_view", 333, 0]].to_json

    #Initilaize the view controller
    @pipe.puts [[0, 4, "if_controller_init", 332, 333, "__test__", {}]].to_json

    #List controllers available
    @pipe.puts [[0, 0, "if_spec_controller_list"]].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "spec", [332]], 6.seconds)
  end
end
