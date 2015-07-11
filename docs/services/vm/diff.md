#VM Diff
Information on the diff system of the vm service.

##How a diff is created
`vm_diff` embodies the creation of a diff. Some aspects of a diff, like a changed `_head` or a changed `_next` are just
simple comparisons. Entry specific vm_diff_entry types, like `+`, need to be in a special order. The order is

  * `vm_diff_entry` types where order is unimportant
    * `M` - Modifications do not rely on index
    * `HEAD_M` - Head can change whereever
    * `NEXT_M` - Next can change wherever
  * `vm_diff_entry` types in order they should be in the `vm_diff` log:
    1. Deletions (`-`)
    2. Moves (`>`)
    3. Insetions (`+`)

##Helpers
###Functional Kernel
  * `vm_diff(old_page, new_page)` - Returns an array of type `vm_diff` w.r.t to the old page.  E.g. if A appears in `new_page`, but not `old_page`
      then it is an insertion.
  * `vm_diff_replay(page, diff)` - Will run the diff against the page; the page will be modified. This will have no effect on any changelists.

##Data Types
###`vm_diff`
```ruby
vm_diff_log_schema = [
  <<vm_diff_entry>>,
  <<vm_diff_entry>>,
  ...
]
```

###`vm_diff_entry`
Each `vm_diff_entry` is an array with the form `[type_str, *args]`. The types are:
```ruby
#Entry Insertion
#eindex - The index of the insertion.
#ehash - A hash that contains the entry.
["+", eindex, ehash]

#Entry Deletion
#eid - The id of the entry that was deleted.
["-", eid]

#Entry Modification
#ehash - A hash that contains the new entry to replace the old entry.
["M", ehash]

#Entry Move
#to_index - The index, an integer, that the entry should be insertad at
#eid - The id of the entry to be moved to the to_index
[">", to_index, eid]

#Head or next pointer changed
["HEAD_M", new_head_id]
["NEXT_M", new_next_id]
```
