#This was created later than the controllers, so not all macros may be 
#tested in here.  Additionally, some macros may be harder to test, so 
#this contains mostly non-side-effect (functionalish) macros that do not
#make other function calls. e.g. vm page macros

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_macro_spec" do
  include_context "kern"

  it "Can use the NewPage macro" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/vm/macros/new_page_c.rb')
    ctx.eval %{
      base = _embed("controller", 0, {}, null);
      int_dispatch([]);
    }

    #Check the page variable 
    page = JSON.parse(ctx.eval("JSON.stringify(page)"))
    expect(page).to eq({
      "_head" =>  nil,
      "_next" =>  nil,
      "entries" => []
    })
  end
end
