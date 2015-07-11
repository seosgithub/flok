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

The order is special; imagine that we want to calculate a diff for a `from` list to a `to` list

```ruby
#from  to
#---# #---#      
#-A-# #-A-#    
#-B-# #-D-#    
#-F-# #-C-#    
#-D-# #-B-#    
#---# #-E-#    
      #---#    
```

First we remove all entries in the `to` list that are not on the `from` list. All these entries are `+` entries, we take note of the index they were removed from.

```ruby
#Removed C at index 2 and E and index 4
#to
#---#
#-A-#
#-D-#
#-B-#
#---#
```

Second we remove all entries in the `from` list that are not in the `to` list. All the removed entries are `-` deletions.
```ruby
#Removed F
#from
#---#
#-A-#
#-B-#
#-D-#
#---# 
```

Last, we compare the `to` and `from` lists making note of how we could remove and re-insert items in the `to` list to re-create the `from` list
```ruby
#from    to
#---#    #---#      
#-A-#    #-A-#    
#-B-# => #-D-#    
#-D-#    #-B-#      
#---#    #---#

#1. Remove B and Insert at index 2 [">", "b_id", 2]
#from
#---#
#-A-#
#-D-#
#-B-#
#---#
```
Now we have all the pieces of the diff. If played in the order `delete`, `move`, and then `insert`, the resulting list will always be the same. `modifications` are position independent so they can be done at any time.

####Example replay `from => to`
```ruby
#from   # diff
#---#   # (-) F
#-A-#   # (>) b_id to index:2
#-B-#   # (+) C @ index 2
#-F-#   # (+) E @ index 4
#-D-#
#---#

#1) (-) F
#---#
#-A-#
#-B-#
#-D-#
#---#

#2) (>) b_id to index:2 
#---#
#-A-#
#-D-#
#-B-#
#---#

#3) (+) C @ index 2 
#---#
#-A-#
#-D-#
#-C-#
#-B-#
#---#

#4) (+) E @ index 4 
#---#
#-A-#
#-D-#
#-C-#
#-B-#
#-E-#
#---#

Now `from` is the original `to`
```

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
