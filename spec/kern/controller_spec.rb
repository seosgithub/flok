#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_spec" do
  include_context "kern"

  #Controller initialization is done via `_embed` or the `embed` macro if you are inside a controller. Embedding
    #1. Requests a set of sequential pointers via `tels`, `n(spots)`.  `main` is always a spot, so there is always at least one pointer. The first pointer is the base.
    #2. Initializes the root view of the controller with the base pointer and retrieve the spots array from the controller `main` + whatever you declared in `spots`
    #3. Attaches that view to the `view pointer` (which is a tele-pointer) given in the embed call.
    #4. Sets up the view controller's info structure.
    #5. Explicitly registers the view controller's info structure with the `root view base pointer` via `tel_reg_ptr(info, base)`
    #6. Invokes the view controllers `on_entry` function with the info structure.
  it "Can initiate a controller via _embed" do
    #Compile the controller
    ctx = compile "controller1"

    #Run the embed function
    ctx.eval %{
      //Get a new base pointer
      var base = tels(1);

      //Call embed
      _embed("test", base, {});
    }
  end
end
