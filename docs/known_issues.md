#Known issues & Bugs

  0000. A `every` event used in a controller's action will time correctly on the first action, but subsequent actions will be off by at most 3 ticks.
  This is because we do not have any way (currently) to reset the timing queue in the controller as it reisters for all timing events at init. See
  "Does not call intervals of other actions; and still works when switching back actions" in `spec/kern/controller_spec.rb` 
  0002. `vm_cache_write_sync_pending` in the `vm` service relies on page_ids, but this would cause a collision on two pages named the same thing. This
   needs to integrate the namespace.
