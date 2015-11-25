# Hooks in the kernel

## How user-generators work
As mentioned in the [User Handbook | Hooks](../user_handbook/hooks.md), user-generators are compiled into the kernel when the user
defines hooks in `./config/hooks.rb`. These hooks are then interpreted when the `flok` user binary runs through build process 
via `UserHooksToManifestOrchestrator`. The orchestrator then evaluates the `./config/hooks.rb` through the `UserHooksDSL` which
captures each hook request as an unvalidated expression; that expression is then run through a generator block which yields
a hook manifest entry that can be added to the hooks manifest. The hooks compiler then takes the manifest and runs over the source
code with the manifest to inject code where needed.

## How hook entry points get placed in source
Hook entry points are not magical.  They are hand placed, typically via ERB, into source as they require some JSON encoded data.

## Hook events
Hooks are emitted into user-space via the `hook` module [Hook](../mod/hooks.md).
