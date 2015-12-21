Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:rtc_spec" do
  include_context "kern"

  it "Does set the global information when receiving the int_about_poll_cb message" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    @driver.int("int_about_poll_cb", [{
      "platform" => "test",
      "language" => "en-us",
      "udid" => "foo-bar"
    }])

    dump = ctx.evald %{
      dump.platform = get_platform();
      dump.language = get_language();
      dump.udid = get_udid();
    }

    expect(dump["platform"]).to eq("test")
    expect(dump["language"]).to eq("en-us")
    expect(dump["udid"]).to eq("foo-bar")
  end
end
