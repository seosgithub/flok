service :vm do
  global %{
    //Some of the shared datatypes
    ////////////////////////////////////////////////////////////////////////////////////////////
    //Cache contains a blank hash for each namespace
    vm_cache = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    vm_dirty = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    vm_bp_to_nmap = {};
    vm_pager_waiting_read = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };
    vm_cache_write_sync_pending = {};

    //Notification listeners, converts ns+key to an array of base pointers
    vm_notify_map = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };
    ////////////////////////////////////////////////////////////////////////////////////////////

    //Cache
    function vm_cache_write(ns, page) {
      <% if @debug %>
        if (vm_transaction_in_progress === false) { throw "vm_cache_write called but a transaction was not in progress. Make sure to call vm_transaction_begin and vm_transaction_end" }
        if (vm_transaction_ns !== null && vm_transaction_ns !== ns) { throw "vm_cache_write called, and is within a vm_transaction but the ns given: " + ns + " does not match the transaction ns of: " + vm_transaction_ns };
      <% end %>

      //Namespace is needed for vm_transaction_end
      vm_transaction_ns = ns;

      vm_rehash_page(page);

      var old = vm_cache[ns][page._id];
      if (old) {
        //Same, don't do anything
        if (old._hash === page._hash) { return; }

        //Diff
        vm_transaction_diffs.push(vm_diff(old, page));
        vm_transaction_changed_ids.push(page._id);
      }

      vm_dirty[ns][page._id] = page;
      vm_cache[ns][page._id] = page;

      //List of controllers to notify synchronously
      var sync_waiting_controllers = vm_cache_write_sync_pending[page._id];

      //Map that holds all controllers synchronously sent (used to avoid sending
      //those controllers that are also on vm_notify_map a second message)
      var sync_sent_map = {};
		
      //You *cannot* int_event in the middle of this function, it must be deferred
      //to the end of the function as all the code here is critical. int_event will
      //synchronously execute and can cause side effects if say the int_event causes
      //a controller to be embedded which then watches a page, it will get hit in the
      //block that looks for a vm_notify_map (which it is now apart of)
      var sync_read_res_waiting = [];
	  
      //Notify all controllers that requested to be notified synchronously
      //typically via watch(sync:)
      if (sync_waiting_controllers !== undefined) {
        for (var i = 0; i < sync_waiting_controllers.length; ++i) {
          var c = sync_waiting_controllers[i];

          //Save so we don't send the same controller during the async part if the controller
          //also happends to be part of vm_notify_map (it watched)
          sync_sent_map[c] = true;

          //Notify controller synchronously
          sync_read_res_waiting.push(c);
        }
      }

      //Try to lookup view controller(s) to notify
      var nbp = vm_notify_map[ns][page._id];
      if (nbp) {
        for (var i = 0; i < nbp.length; ++i) {
          var cbp = nbp[i];
          //Only send if we didn't just send it above in the previous
          //block synchronously
          if (sync_sent_map[cbp] === undefined) {
            int_event_defer(cbp, "read_res", page);
          }
        }
      }

      //Clear the sync_waiting_controllers
      delete vm_cache_write_sync_pending[page._id];
      
      //Now execute the synthronous int_events
      for (var i = 0; i < sync_read_res_waiting.length; ++i) {
        int_event(sync_read_res_waiting[i], "read_res", page);
      }
    }

    function vm_pageout() {
      <% @options[:pagers].each do |p| %>
        //Get id_to_page mappings
        var id_to_page = vm_dirty["<%= p[:namespace] %>"];
        if (id_to_page) {
          var ids = Object.keys(id_to_page);

          //For each mapping, write the page
          for (var i = 0; i < ids.length; ++i) {
            var p = id_to_page[ids[i]];
            SEND("disk", "if_per_set", "<%= p[:namespace] %>", ids[i], p);
          }
        }
        <% end %>

      vm_dirty = {
        <% @options[:pagers].each do |p| %>
          <%= p[:namespace] %>: {},
        <% end %>
      };
    }

    //Part of the persist module
    //res is page
    function int_per_get_res(s, ns, id, res) {
      if (ns === "__reserved__") {
        if (id === "vm_unsynced") {
          if (res === null) { return; }
          var cached_vm_unsynced = res;

          <% @options[:pagers].each do |p| %>
            //Make sure disk has the old namespace
            if (cached_vm_unsynced.<%= p[:namespace] %> !== undefined) {
              //Get all the ids from the old namespace
              var ids = Object.keys(cached_vm_unsynced.<%= p[:namespace] %>)
              for (var i = 0; i < ids.length; ++i) {
                vm_unsynced.<%= p[:namespace] %>[ids[i]] = cached_vm_unsynced.<%= p[:namespace] %>[ids[i]];
              }
            }
          <% end %>
        }
        return;
      }

      if (res !== null) {
        //Write out to the cache
        vm_transaction_begin();
        vm_cache_write(ns, res);
        vm_transaction_end();

      } else {
        //Result was blank, signal all controllers that read synchronously
        var sync_waiting_controllers = vm_cache_write_sync_pending[id];
        if (sync_waiting_controllers !== undefined) {
          for (var i = 0; i < sync_waiting_controllers.length; ++i) {
            var c = sync_waiting_controllers[i];

            //Notify controller synchronously
            int_event(c, "read_res", {});
          }
        }

        //Remove all controllers from notification list
        delete vm_cache_write_sync_pending[id];
      }

      //Check if a pager is waiting for this read to complete a write request
      var page_awaiting_write = vm_pager_waiting_read[ns][id];
      if (page_awaiting_write !== undefined) {
        <% @options[:pagers].each_with_index do |p, i| %>
          <% if i == 0 %>
            if ("<%= p[:namespace] %>" === ns) {
              <%= p[:name] %>_write(page_awaiting_write);
            }
          <% else %>
            else if ("<%= p[:namespace] %>" === ns) {
              <%= p[:name] %>_write(page_awaiting_write);
            }
          <% end %>
        <% end %>

        //Clear waiting entry
        delete vm_pager_waiting_read[ns][id];
      }
    }

    <% if @debug %>
      vm_write_list = [];
    <% end %>

    //Generic Page Helpers
    ///////////////////////////////////////////////////////////////////////////
    function vm_create_page(id) {
      if (id === undefined) {
        id = gen_id();
      }

      var page = {
        _id: id,
        _head: null,
        _next: null,
        _hash: null,
        entries: [],
        __index: {},
      };

      return page;
    }

    function vm_copy_page(page) {
      var page = {
        _id: page._id,
        _head: page._head,
        _next: page._next,
        _hash: page._hash,
        entries: JSON.parse(JSON.stringify(page.entries)),
      };

      return page;
    }

    function vm_rehash_page(page) {
      var z = 0;

      //head and next are optional
      if (page._head) { var z = crc32(0, page._head) }
      if (page._next) { z = crc32(z, page._next) }

      z = crc32(z, page._id)

      //Hash differently based on type
      var e = page.entries;
      for (var i = 0; i < e.length; ++i) {
        z = crc32(z, e[i]._sig);
      }

      page._hash = z.toString();
    }

    function vm_reindex_page(page) {
      page.__index = {};
      for (var i = 0; i < page.entries.length; ++i) {
        page.__index[page.entries[i]._id] = i;
      }
    }

    function vm_entry_with_id(page, eid) {
      var _idx = page.__index[eid];
      return page.entries[_idx];
    }

    function vm_del_entry_with_id(page, eid) {
      var _idx = page.__index[eid];
      if (_idx > -1) {
        page.entries.splice(_idx, 1);
      }
      vm_reindex_page(page);
    }

    function vm_set_entry_with_id_key_val(page, eid, key, val) {
      var _idx = page.__index[eid];

      //Do we have the entry?
      if (_idx > -1) {
        //Great, then set the id and _sig
        page.entries[_idx][key] = val;
        page.entries[_idx]._sig = gen_id();
      } else {
        //Nope, create the entry
        var entry = {_sig: gen_id(), _id: eid}
        entry[key] = val;
        page.entries.push(entry);
        vm_reindex_page(page);
      }
    }

    ///////////////////////////////////////////////////////////////////////////

    //vm_diff helpers
    ///////////////////////////////////////////////////////////////////////////
    function vm_diff(old_page, new_page) {
      var diff_log = [];
      if (old_page._head !== new_page._head) {
        diff_log.push(["HEAD_M", new_page._head])
      }

      if (old_page._next !== new_page._next) {
        diff_log.push(["NEXT_M", new_page._next])
      }

      var from_entries = old_page.entries;
      var to_entries = new_page.entries;

      //Calculated lists
      var ins = [];
      var dels = [];
      var moves = [];
      var modify = [];

      //a_prime is Union (ordered) of from
      //b_prime is Union (ordered) of to
      var a_prime = [];
      var b_prime = [];

      //Save all entry sigs
      var from_entries_sig  = [];
      for (var i = 0; i < from_entries.length; ++i) {
        from_entries_sig[from_entries[i]._id] = from_entries[i]._sig;
      }

      //Need to re-index page for the modify code which needs to know the index
      //of the id of the new entry
      vm_reindex_page(new_page);

      //Save all the entry sigs
      var to_entries_sig  = [];
      for (var i = 0; i < to_entries.length; ++i) {
        to_entries_sig[to_entries[i]._id] = to_entries[i]._sig;
      }

      //I. Calculate all elements in to_entries that are not in from_entries
      //for each one of those elements, mark it as insertion and remove them in reverse order.
      for (var i = 0; i < to_entries.length; ++i) {
        //Does the entry *not* exist in from_entries?
        var to_entry_id = to_entries[i]._id;
        if (from_entries_sig[to_entry_id] === undefined) {
          ins.push(["+", i, to_entries[i]]);
        } else {
          //The entry *does* exist, therefore it must be part of the shared
          b_prime.push(to_entries[i]._id);
        }
      }

      for (var i = 0; i < from_entries.length; ++i) {
        var from_entry_id = from_entries[i]._id;
        if (to_entries_sig[from_entry_id] === undefined) {
          dels.push(["-", from_entries[i]._id]);
        } else {
          a_prime.push(from_entries[i]._id);

          if (from_entries[i]._sig != to_entries_sig[from_entry_id]) {
            modify.push(["M", new_page.entries[new_page.__index[from_entry_id]]]);
          }
        }
      }

      //*==================================*
      //| Wild UNOPTIMIZED ALGORITHM       |
      //|                                  |
      //| appeared!                        |
      //|                                v |
      //*==================================*
      while(1) {
        var wdiff = 0;
        var wb_index;
        var wa_index;

        for (var i = 0; i < a_prime.length; ++i) {
          var b_index = b_prime.indexOf(a_prime[i]);
          var diff = b_index - i;

          if (Math.abs(diff) > Math.abs(wdiff)) {
            wdiff = diff;
            wa_index = i;
            wb_index = b_index;
          }
        }

        if (Math.abs(wdiff) > 0) {
          var r = a_prime.splice(wa_index, 1);
          a_prime.splice(wb_index, 0, r[0]);

          moves.push([">", wb_index, r[0]]);
        } else {
          break
        }
      }

      var res = diff_log.concat(dels).concat(modify).concat(moves).concat(ins);
      return res;
    }

    function vm_diff_replay(page, diff) {
      for (var i = 0; i < diff.length; ++i) {
        vm_reindex_page(page);
        var e = diff[i];

        //vm_diff type
        var type = e[0];
        if (type === "+") {
          var eindex = e[1];
          var entry = e[2];

          //Ignore insertion if an element already exists with the given id
          if (page["__index"][entry["_id"]] === undefined) {
            //Insertion
            page.entries.splice(eindex, 0, entry);
          }
        } else if (type === ">") {
          var eindex = e[1];
          var entry_id = e[2];

          var current_index = page["__index"][entry_id];
          if (current_index !== undefined) {
            var entry = page.entries.splice(current_index, 1)[0];
            page.entries.splice(eindex, 0, entry);
          }
        } else if (type === "M") {
          var entry = e[1];

          //Take out old, put in new
          if (page["__index"][entry["_id"]] !== undefined) {
            page.entries.splice(page["__index"][entry["_id"]], 1, entry);
          }
        } else if (type === "-") {
          var eid = e[1];

          var index = page.__index[eid];

          //Take out
          if (page["__index"][eid] !== undefined) {
            page.entries.splice(index, 1);
          }
        } else if (type === "HEAD_M") {
          page._head = e[1];
        } else if (type === "NEXT_M") {
          page._next = e[1];
        }
      }
    } 
    ///////////////////////////////////////////////////////////////////////////

    //Commit helpers
    ///////////////////////////////////////////////////////////////////////////
    function vm_commit(older, newer) {
      newer.__changes_id = gen_id();

      if (older.__changes && !older.__base) {
        newer.__base = older;
      } else if (older.__changes) {
        newer.__base = older.__base;
      }

      if (older.__base) {
        newer.__changes = vm_diff(older.__base, newer);
      } else {
        newer.__changes = vm_diff(older, newer);
      }
    }

    function vm_rebase(newer, older) {
      if (newer.__changes && !newer.__base) {
        <% if @debug %>
          if (newer.__changes_id === undefined) {
            throw "__changes_id did not exist on newer: " + JSON.stringify(newer) + " but it did have __changes";
          }
        <% end %>
        older.__changes = newer.__changes;
        older.__changes_id = newer.__changes_id;

        vm_diff_replay(older, older.__changes);
      } else if (newer.__changes && newer.__base) {
        <% if @debug %>
          if (newer.__changes_id === undefined) {
            throw "__changes_id did not exist on newer: " + JSON.stringify(newer) + " but it did have __changes";
          }
        <% end %>

        //Reconstruct the __base by playing newer.__base.__changes ontop of older (which is the base we are rebasing on)
        //Imagine that you texted a teacher changes, but are unsure whether that teacher has received those changes, meanwhile,
        //the teacher texts you a new fresh copy of the page. You must now keep track of the changes you texted her (newer.__base.__changes)
        //while still being able to create a new list of changes for any future changes that you make (as we diff pages to create the changes)
        //So we reconstruct the newer.__base page  by taking what the teacher gave us, trash the newer.__base page, but replay the changes
        //that newer.__base.__changes had onto the copy the teacher gave us. E.g. we cross out "Sally" on our list, text teacher that we crossed
        //out sally. Teacher gave us a new list that has "Bill" Crossed out. We Then take the new list and cross out "Sally" and call that our new
        //base page.
        vm_diff_replay(older, newer.__base.__changes);

        //Copy the page, we need to use the copy as a '__base' page because we want the non-copied older page to be the non-base version. (And we
        //will make it the 'non' base version by again, replaying changes from the 'newer.__changes') after setting the __base to the copy.
        var older_copy = vm_copy_page(older);
        older_copy.__changes = newer.__base.__changes;
        older_copy.__changes_id = newer.__base.__changes_id;
        vm_reindex_page(older_copy);
        older.__base = older_copy;

        //Now update the older page w/ the `newer.__changes`
        vm_diff_replay(older, newer.__changes);

        //Calculate diff for older
        older.__changes = vm_diff(older.__base, older);
        older.__changes_id = gen_id();
      }
    }

    function vm_mark_changes_synced(page, changes_id) {
      if (page.__base === undefined && changes_id === page.__changes_id) {
        delete page.__changes;
        delete page.__changes_id;
      } else if (page.__base !== undefined && changes_id === page.__base.__changes_id) {
        delete page.__base;
      }
    }
    ///////////////////////////////////////////////////////////////////////////

    //vm transaction helpers
    ///////////////////////////////////////////////////////////////////////////
    vm_transaction_in_progress = false;
    function vm_transaction_begin() {
      <% if @debug %>
        if (vm_transaction_in_progress === true) { throw "vm_transaction_begin called but a transaction was already in progress" }
      <% end %>
      vm_transaction_in_progress = true;
      vm_transaction_diffs = [];
      vm_transaction_changed_ids = [];
      vm_transaction_ns = null;
    }

    function vm_transaction_end() {
      <% if @debug %>
        if (vm_transaction_in_progress === false) { throw "vm_transaction_end called but vm_transaction_begin was never called" }
      <% end %>
      vm_transaction_in_progress = false;

      for (var i = 0; i < vm_transaction_changed_ids.length; ++i) {
        var page_id = vm_transaction_changed_ids[i];
        var bps = vm_notify_map[vm_transaction_ns][page_id];
        if (bps !== undefined) {
          pieces = [];
          for (var x = 0; x < vm_transaction_diffs[i].length; ++x) {
            //Get diff entry
            var diff_entry = vm_transaction_diffs[i][x];
            pieces.push(diff_entry);

            //For all listening controllers
            for (var y = 0; y < bps.length; ++y) {
              var bp = bps[y];

              if (diff_entry[0] === "M") {
                int_event_defer(bp, "entry_modify", {page_id: page_id, entry: diff_entry[1]});
              } else if (diff_entry[0] === "-") {
                int_event_defer(bp, "entry_del", {page_id: page_id, entry_id: diff_entry[1]});
              } else if (diff_entry[0] === ">") {
                var eindex = diff_entry[1];
                var eid = diff_entry[2];
                int_event_defer(bp, "entry_move", {entry_id: eid, from_page_id: page_id, to_page_id: page_id, to_page_index: eindex});
              } else if (diff_entry[0] === "+") {
                var eindex = diff_entry[1];
                var entry = diff_entry[2];
                int_event_defer(bp, "entry_ins", {page_id: page_id, index: eindex, entry: entry});
              } else if (diff_entry[0] === "NEXT_M") {
                int_event_defer(bp, "next_changed", {page_id: page_id, value: diff_entry[1]});
              } else if (diff_entry[0] === "HEAD_M") {
                int_event_defer(bp, "head_changed", {page_id: page_id, value: diff_entry[1]});
              } 
            }
          }

          //throw JSON.stringify(pieces);
        }
      }
    }
    ///////////////////////////////////////////////////////////////////////////

    //vm unsynced
    ///////////////////////////////////////////////////////////////////////////
    //Unsynced page ids to integer vm_unsynced[bp][page_id] = '0' or '1'
    //where 0 is freshly added and ignored on the first pass of the daemon
    vm_unsynced = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //Does it need to be written to disk?
    vm_unsynced_is_dirty = false;

    function vm_pg_mark_needs_sync(ns, page_id) {
      vm_unsynced_is_dirty = true;

      //Add to list
      vm_unsynced[ns][page_id] = 0;

      //Notify pager immediately (daemon will not notify pager on first tick to avoid calling pager's sync to soon)
      <% @options[:pagers].each_with_index do |p, i| %>
        <% if i == 0 %>
          if ("<%= p[:namespace] %>" === ns) {
            <%= p[:name] %>_sync(page_id);
          }
        <% else %>
          else if ("<%= p[:namespace] %>" === ns) {
            <%= p[:name] %>_sync(page_id);
          }
        <% end %>
      <% end %>
    }

    function vm_pg_unmark_needs_sync(ns, page_id) {
      vm_unsynced_is_dirty = true;

      delete vm_unsynced[ns][page_id];
    }

    function vm_pg_sync_wakeup() {
      //Iterate through all the unsynced entries an increment any entries that are 0 to 1
      <% @options[:pagers].each do |p| %>
        //Get all page ids in a namespace
        var page_ids = Object.keys(vm_unsynced.<%= p[:namespace] %>);

        for (var i = 0; i < page_ids.length; ++i) {
          if (vm_unsynced.<%= p[:namespace] %>[page_ids[i]] === 0) {
            vm_unsynced.<%= p[:namespace] %>[page_ids[i]] = 1;
          } else {
            //Notify pager
            <%= p[:name] %>_sync(page_ids[i]);
          }
        }
      <% end %>
    }

    vm_unsynced_paged_in = false;
    function vm_pg_sync_pagein() {
      //Only pages-in if necessary
      if (vm_unsynced_paged_in === false) {
        vm_unsynced_paged_in = true;

        //Send a disk read request
        SEND("disk", "if_per_get", "vm", "__reserved__", "vm_unsynced");
      }
    }

    function vm_pg_sync_pageout() {
      //Only page-out if necessary
      if (vm_unsynced_is_dirty === true) {
        vm_unsynced_is_dirty = false;
        SEND("disk", "if_per_set", "__reserved__", "vm_unsynced", JSON.stringify(vm_unsynced));
      }
    }
    ///////////////////////////////////////////////////////////////////////////
  }

  on_wakeup %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    <% if @debug %>
      vm_did_wakeup = true;
    <% end %>

    //Call init functions
    <% @options[:pagers].each do |p| %>
      <%= p[:name] %>_init("<%= p[:namespace] %>", <%= (p[:options] || {}).to_json %>);
    <% end %>
  }

  on_sleep %{
  }

  on_connect %{
    vm_bp_to_nmap[bp] = {};
  }

  on_disconnect %{
    //We need to remove all the entries in vm_notify_map, but we only
    //get an array of bp for each array in vm_notify_map[ns][key]...
    //So we use the inverted lookup of vm_bp_to_nmap[bp][ns][key] to get a pointer
    //to vm_notify_map[ns][key] and associated index. We then delete all the
    //entries out of vm_notify_map

    //Foreach namespace
    var nss = Object.keys(vm_bp_to_nmap[bp]);
    for (var i = 0; i < nss.length; ++i) {
      //Namespace node
      var nn = vm_bp_to_nmap[bp][nss[i]];

      //Get all keys (which are ids)
      var nnk = Object.keys(nn);

      for (var x = 0; x < nnk.length; ++x) {
        //Array contains [node (pointer to vm_notify_map[ns][key]), index] where index points to base pointer of this
        //controller in the array
        var arr = nn[nnk[x]][0]
        var idx = nn[nnk[x]][1]

        //Remove
        arr.splice(idx, 1);
      }

    }

    //Now we just clean up vm_bp_to_nmap because it's no longer used
    delete vm_bp_to_nmap[bp];
  }

  on "write", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    //We are going to fix the _hash on the page and __index
    vm_reindex_page(params.page);
    vm_rehash_page(params.page);

    <% if @debug %>
      vm_write_list.push(params.page);
    <% end %>

    //If the page does not exist, we need to send a disk request for a read because we may
    //need to commit to the page
    if (vm_cache[params.ns][params.page._id] === undefined) {
      //Save the page into the waiting list or throw an exception if there's already a write
      //queued, at this time, we do not support multiple writes in the same frame
      if (vm_pager_waiting_read[params.ns][params.page._id] !== undefined) {
        throw "vm on_write was called multiple times within the same frame (I.e. page did not exist, so we read it from disk, but that disk read didn't come back before the page was attempted to written again). This is not terribly illegal but it can lead to undefined behavior.";
      }
      vm_pager_waiting_read[params.ns][params.page._id] = params.page;

      //Notify the disk
      SEND("disk", "if_per_get", "vm", params.ns, params.page._id);
    } else {
      //Else, just notify the pager right away
      <% @options[:pagers].each do |p| %>
        if (params.ns === "<%= p[:namespace] %>") {
          <%= p[:name] %>_write(params.page);
        }
      <% end %>
    }
  }

  on "watch", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    //Cache entry
    var cache_entry = vm_cache[params.ns][params.id];

    //Ensure map exists
    ////////////////////////////////////////////////
    var b = vm_notify_map[params.ns][params.id];
    if (!b) {
      b = [];
      vm_notify_map[params.ns][params.id] = b;
    }

    //Check if it exists, if it's already being watched, ignore it
    var midx = vm_notify_map[params.ns][params.id].indexOf(bp)
    if (midx != -1) {
      return;
    }

    b.push(bp)
    ////////////////////////////////////////////////

    //Add to vm_bp_to_nmap
    ////////////////////////////////////////////////
    //Construct 
    if (vm_bp_to_nmap[bp][params.ns] === undefined) { vm_bp_to_nmap[bp][params.ns] = {}; }

    //Add reverse mapping, length-1 because it was just pushed
    vm_bp_to_nmap[bp][params.ns][params.id] = [b, b.length-1];

    //If cache exists, then signal controller *now* while we wait for the pager
    if (cache_entry) {
      //If sync flag is set, then send the data *now*
      if (params.sync) {
        int_event(bp, "read_res", cache_entry);
      } else {
        int_event_defer(bp, "read_res", cache_entry);
      }
    }

    //Send a request now for disk read for sync
    if (!cache_entry) {
      if (params.sync !== undefined && params.sync === true) {
        //Add ourselves to synchronous read list so the next disk read will
        //send a synchronous event to us (and then clear). We will not get the 
        //normal asynhronous read. Additionally, we may also get a `{}` page indicating
        //that the page is blank
        vm_cache_write_sync_pending[params.id] = vm_cache_write_sync_pending[params.id] || []; 
        vm_cache_write_sync_pending[params.id].push(bp);
        SEND("main", "if_per_get", "vm", params.ns, params.id);
      } else {
        SEND("disk", "if_per_get", "vm", params.ns, params.id);
      }
    }

    //Do not signal pager if there is a watch request already in place
    //as pager already knows; if it's equal to 1, this is the 'first'
    //watch to go through as we have no info on it but just added it
    if (vm_notify_map[params.ns][params.id].length > 1) { return; }

    //Now load the appropriate pager
    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_watch(params.id, cache_entry);
      }
    <% end %>
  }

  on "read_sync", %{
    <% if @debug %>
      if (params.id === undefined) {
        throw "You need to pass an id for the page in read_sync request";
      }

      if (params.ns === undefined) {
        throw "You need to pass an ns for the page in read_sync request";
      }
    <% end %>

    var cache_entry = vm_cache[params.ns][params.id];
    if (cache_entry !== undefined) {
      int_event(bp, "read_res", cache_entry);
    } else {
      //Set this controller as awaiting as synchronous response
      vm_cache_write_sync_pending[params.id] = vm_cache_write_sync_pending[params.id] || []; 
      vm_cache_write_sync_pending[params.id].push(bp);
      SEND("main", "if_per_get", "vm", params.ns, params.id);
    }
  }

  on "unwatch", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    //It won't have an array if it was never watched
    if (vm_notify_map[params.ns][params.id] === undefined) {
      return;
    }

    //Get the position of bp in the watch array, this may not exist, in which case
    //this controller is not actually watching it.
    var midx = vm_notify_map[params.ns][params.id].indexOf(bp)
    if (midx === -1) {
      return;
    }

    vm_notify_map[params.ns][params.id].splice(midx, 1);
    
    //Remove from notify map if no entries exist
    if (vm_notify_map[params.ns][params.id].length === 0) { delete vm_notify_map[params.ns][params.id]; }

    delete vm_bp_to_nmap[bp][params.ns][params.id];

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_unwatch(params.id);
      }
    <% end %>
  }

  every 20.seconds, %{
    vm_pageout();
    vm_pg_sync_wakeup();
    vm_pg_sync_pageout();
  }

  every 2.seconds, %{
    vm_pg_sync_pagein();
  }
end
