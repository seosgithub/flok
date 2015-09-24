#Hooks
Hooks are a way for users to handle things like animated transitions (including gesture-controlled transitions), or global buttons like an android-back button. They are defined in the user's project
under `./config/hooks.rb` and use their own DSL language for communicating what kind of events are being watched for. When a hooked condition occurrs, the kernel notifies the client of the condition.
It was decided not to allow kernel notifications in hooks because services seem to be the more appriate mechanism for kernel notifications and monitoring.

##How hooks are compiled into the kernel
The user's `./config/hooks.rb` file is compiled and then evaluated statically to get a listing of all the controllers that the hooks can apply to. Then the compiler goes over each controller
and inserts code at particular hook detection points; the nature of the insertions is up to the particular hooking context.

##Synchronous vs Asynchronous Hooks
Whether a hook is synchronous or not synchronous depends entirely on the type of hook in question. An example of a possible synchronous hook is a hook jkkkkkkkkkk..j

##Hooking check points
Each controller has a plethora of functions that determine it's lifetime and behaviours. These functions include the actions of creation, destruction, embedding, pushing actions, talking to services, etc.
These functions are built into the ctable entry for each controller and possible controller related functions like _embed. Each controller entry point is marked with a special comment marker that has
the following JSON format:

```ruby 
//HOOK_ENTRY[my_name] {foo: "bar"}...
```
The name is the hook name and the params is context specific inforamtion the compiler has embedded. Live variables that are in the context of the hook detection point are described in each hook detection point below.

  * `controller_will_goto` - The controller is about to invoke the Goto macro and switch actions or it has just entered the first action from choose_action (which is a Goto).
    * params (static generated)
      * `controller_name` - The controller name that this entry effects
      * `from_action` - The name of the action we are coming from
      * `to_action` - The name of the action we are going to
    * Useful (dynamic) variables
      * `old_action` - The previous action, equal to `from_action` but in dynamic form. If there is no action, this is set to `choose_action`. Not sure why you would use this
      * `__info__.action` - The name of the new action
  * `${controller_name}_did_destroy` - The controller has *just* been destroyed

##Hooks Compiler
The hooks compiler is able to take the hook entry points and inject code into them via a set of `HooksManifestEntries` which are bound togeather via a `HooksManifest`. The actual
compiler only takes the original source code, the `HooksManifest` and then spits out a version that no longer contains the special hook entry comments and contains any
injected hooking code.


##User Hook Generators

###./config/hooks.rb
The hooks configuration file contains the user's DSL hooks. This file is not compiled directly by `HooksManifest` but rather many intermediate `UserHookGenerator` are
used to parse the `./config/hooks.rb` and this conversion is orchestrated by the singleton `UserHooksToManifestOrchestrator`. Each `UserHook` is defined in the `./lib/user_hook_generators.rb`
and are never meant to directly be created by users.

Each hook generator instance defined in `./config/hooks.rb` contains code that looks like
```ruby
hooks :hook_gen_name, :as => :client_event do
  #Each hook generator has it's own set of rules for what you
  #place inside the block
end
```
Here the genterator name is `hook_gen_name` and the client will receive the event `client_event` when this hook generator decides that a hooked event
should be triggered. What the client receives is up to the hook generator and is listed in each generator's information below.

####What's available in this ./config/hooks.rb?

##### goto
This generator allows you to intercept a controller switching actions and/or when the controller is created (As all controllers start from the null state of `choose_action`).
The client receives:
```ruby
{
  from_action: from_action_name, #This is 'choose_action' if the controller was just created
  to_action: to_action_name,
}
```

Example ./config/hooks.rb
```ruby
hook :goto, :as => :goto do
  controller :my_controller
end
```

Anytime the controller `my_controller` switches actions, the client receives the hook notify event `goto` and
the information described above. (If the controller is created, the client also receives an event which contains
the from_action as `choose_action` and the to_action as the first action)
