Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:rtc_spec" do
  include_context "kern"

  it "Does update the epoch when receiving the int_rtc message" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    @driver.int("int_rtc", [555])
    dump = ctx.evald %{
      dump.time = time()
    }
    expect(dump["time"]).to eq(555)

    @driver.int("int_rtc", [556])
    dump = ctx.evald %{
      dump.time = time()
    }
    expect(dump["time"]).to eq(556)
  end
end
