Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:dispatch_spec" do
  include_context "kern"

  it "Can call spec_dispatch" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    #Register callout
    ctx.eval %{
      spec_dispatch_q(main_q, 2);
    }

    main_q = ctx.dump "main_q"
    expect(main_q).to eq [[0, "spec"], [0, "spec"]]
  end


  #it "Does disptach an unlimited number of items from the main queue" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/blank.rb')

    ##Register callout
    #ctx.eval %{
    #}
  #end
end
