#Dir.chdir File.join File.dirname(__FILE__), '../../'
#require './spec/env/kern.rb'
#require './spec/lib/helpers.rb'
#require './spec/lib/io_extensions.rb'
#require './spec/lib/rspec_extensions.rb'

##The debug controller / ui spec

#RSpec.describe "kern:debug_ui_spec" do
  #include_context "kern"

#it "Can call int_debug_dump_ui and get back root view hierarchy" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller_bare.rb')

    ##Do not run anything
    #ctx.eval %{
      #int_dispatch([]);
    #}

    #@driver.int "int_debug_dump_ui", []

    #@driver.mexpect("if_event", [-333, "debug_dump_ui_res", {
      #"type" => "spot",
      #"name" => "root",
      #"ptr" => 0,
      #"children" => []
    #}])
  #end

 #it "Can call int_debug_dump_ui for one controller correctly" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller_bare.rb')

    ##Do not run anything
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")

    #@driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main"]])
    #@driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    #@driver.mexpect("if_attach_view", [base+1, 0])
    #@driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "index"}])

    #@driver.int "int_debug_dump_ui", []
    #@driver.mexpect("if_event", [-333, "debug_dump_ui_res", {
      #"type" => "spot",
      #"name" => "root",
      #"ptr" => 0,
      #"children" => [
        #{
          #"name" => "my_controller",
          #"ptr" => base,
          #"type" => "vc",
          #"action" => "index",
          #"events" => ["test"],
          #"children" => [
            #{
              #"type" => "view",
              #"name" => "my_controller",
              #"ptr" => base+1,
              #"children" => []
            #}
          #]
        #}
      #]
    #}])
  #end

  #it "Can call int_debug_dump_ui for one controller correctly with spots" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller_spots.rb')

    ##Do not run anything
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")

    #@driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "one", "two"]])
    #@driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    #@driver.mexpect("if_attach_view", [base+1, 0])
    #@driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "index"}])

    #@driver.int "int_debug_dump_ui", []
    #@driver.mexpect("if_event", [-333, "debug_dump_ui_res", {
      #"type" => "spot",
      #"name" => "root",
      #"ptr" => 0,
      #"children" => [
        #{
          #"name" => "my_controller",
          #"ptr" => base,
          #"type" => "vc",
          #"action" => "index",
          #"events" => ["test", "test2"],
          #"children" => [
            #{
              #"type" => "view",
              #"name" => "my_controller",
              #"ptr" => base+1,
              #"children" => [
                #{"name" => "one", "type" => "spot", "children" => [], "ptr" => base+2},
                #{"name" => "two", "type" => "spot", "children" => [], "ptr" => base+3},
              #]
            #}
          #]
        #}
      #]
    #}])
  #end

  #it "Can call int_debug_dump_ui for one controller correctly with spots and one embedded" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller_spots_embed.rb')

    ##Do not run anything
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")

    #@driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "one", "two"]])
    #@driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    #@driver.mexpect("if_attach_view", [base+1, 0])
    #@driver.mexpect("if_init_view", ["my_other_controller", {}, base+5, ["main"]])
    #@driver.mexpect("if_controller_init", [base+4, base+5, "my_other_controller", {}])
    #@driver.mexpect("if_attach_view", [base+5, base+2])
    #@driver.mexpect("if_event", [base+4, "action", {"from" => nil, "to" => "index"}])
    #@driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "index"}])

    #@driver.int "int_debug_dump_ui", []
    #@driver.mexpect("if_event", [-333, "debug_dump_ui_res", {
      #"type" => "spot",
      #"name" => "root",
      #"ptr" => 0,
      #"children" => [
        #{
          #"name" => "my_controller",
          #"ptr" => base,
          #"type" => "vc",
          #"action" => "index",
          #"events" => ["test1"],
          #"children" => [
            #{
              #"type" => "view",
              #"name" => "my_controller",
              #"ptr" => base+1,
              #"children" => [
                #{"name" => "one", "type" => "spot", "children" => [
                  #{
                    #"name" => "my_other_controller",
                    #"ptr" => base+4,
                    #"type" => "vc",
                    #"action" => "index",
                    #"events" => ["test2"],
                    #"children" => [
                      #{
                        #"type" => "view",
                        #"ptr" => base+5,
                        #"name" => "my_other_controller",
                        #"children" => [],
                      #}
                    #]
                  #}
                #], "ptr" => base+2},
                #{"name" => "two", "type" => "spot", "children" => [], "ptr" => base+3},
              #]
            #}
          #]
        #}
      #]
    #}])
  #end

  #it "Can call int_debug_dump_ui for one controller correctly with spots and one embedded that was later removed" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller_spots_embed_removed.rb')

    ##Do not run anything
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([3, "int_event", base, "next", {}]);
    #}

    #base = ctx.eval("base")

    #@driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "one", "two"]])
    #@driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    #@driver.mexpect("if_attach_view", [base+1, 0])
    #@driver.mexpect("if_init_view", ["my_other_controller", {}, base+5, ["main"]])
    #@driver.mexpect("if_controller_init", [base+4, base+5, "my_other_controller", {}])
    #@driver.mexpect("if_attach_view", [base+5, base+2])
    #@driver.mexpect("if_event", [base+4, "action", {"from" => nil, "to" => "index"}])
    #@driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "index"}])

    ##Expect the view to be removed, and for our action to switch
    #@driver.mexpect("if_free_view", [base+5])
    #@driver.mexpect("if_event", [base, "action", {"from" => "index", "to" => "other"}])

    #@driver.int "int_debug_dump_ui", []
    #@driver.mexpect("if_event", [-333, "debug_dump_ui_res", {
      #"type" => "spot",
      #"name" => "root",
      #"ptr" => 0,
      #"children" => [
        #{
          #"name" => "my_controller",
          #"events" => ["test2"],
          #"ptr" => base,
          #"type" => "vc",
          #"action" => "other",
          #"children" => [
            #{
              #"type" => "view",
              #"name" => "my_controller",
              #"ptr" => base+1,
              #"children" => [
                #{"name" => "one", "type" => "spot", "children" => [], "ptr" => base+2},
                #{"name" => "two", "type" => "spot", "children" => [], "ptr" => base+3},
              #]
            #}
          #]
        #}
      #]
    #}])
  #end

  #it "Can go forward and then back and have the correct hierarchy (where a parent controlls children like nav)" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/forward_and_back.rb')

    ##Do not run anything
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("fabric", 0, {}, null);

      #//Drain queue
      #int_dispatch([3, "int_event", base, "next_clicked", {}]);
    #}

    #base = ctx.eval("base")

    #@driver.mexpect("if_init_view", ["fabric", {}, base+1, ["main", "content"]])
    #@driver.mexpect("if_controller_init", [base, base+1, "fabric", {}])
    #@driver.mexpect("if_attach_view", [base+1, 0])
    #@driver.mexpect("if_init_view", ["one", {}, base+4, ["main"]])
    #@driver.mexpect("if_controller_init", [base+3, base+4, "one", {}])
    #@driver.mexpect("if_attach_view", [base+4, base+2])
    #@driver.mexpect("if_event", [base+3, "action", {"from" => nil, "to" => "index"}])
    #@driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "one"}])

    ##Expect the view to be removed, and for our action to switch
    #@driver.mexpect("if_free_view", [base+4])
    #@driver.mexpect("if_init_view", ["two", {}, base+6, ["main"]])
    #@driver.mexpect("if_controller_init", [base+5, base+6, "two", {}])
    #@driver.mexpect("if_attach_view", [base+6, base+2])
    #@driver.mexpect("if_event", [base+5, "action", {"from" => nil, "to" => "index"}])
    #@driver.mexpect("if_event", [base, "action", {"from" => "one", "to" => "two"}])

    #@driver.int "int_debug_dump_ui", []
    #@driver.mexpect("if_event", [-333, "debug_dump_ui_res", {
      #"type" => "spot",
      #"name" => "root",
      #"ptr" => 0,
      #"children" => [
        #{
          #"name" => "fabric",
          #"events" => ["back_clicked"],
          #"ptr" => base,
          #"type" => "vc",
          #"action" => "two",
          #"children" => [
            #{
              #"type" => "view",
              #"name" => "fabric",
              #"ptr" => base+1,
              #"children" => [
                #{"name" => "content", "type" => "spot", "ptr" => base+2, "children" => [
                  #{
                    #"name" => "two",
                    #"events" => [],
                    #"type" => "vc",
                    #"action" => "index",
                    #"ptr" => base+5,
                    #"children" => [
                      #{
                        #"type" => "view",
                        #"name" => "two",
                        #"ptr" => base+6,
                        #"children" => []
                      #}
                    #]
                  #}
                #]}
              #]
            #}
          #]
        #}
      #]
    #}])
  #end

#end
