service :vm do
  global %{
    //Cache contains a blank hash for each namespace
    vm_cache = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };
    vm_transaction_in_progress = false;

    vm_dirty = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //A map of connections that is set to bp => true for every
    //controller that has given 'diff' option in watch
    vm_diff_bps = {};

    vm_bp_to_nmap = {};

    //Notification listeners, converts ns+key to an array of base pointers
    vm_notify_map = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //When you need to make writes from an external source like a server that may
    //not be fully in-sync and sometimes integrates changelists. cl_id is optional.
    //If no cl_id is specified, (changelist id), then the page will be written and
    //then changes will just be replayed. If cl_id is specified, the changelist
    //will remove the top most (fault if the id does not match), and then replay the
    //changelist.
    /*
    function vm_cache_write_sync(ns, page, cl_id) {
      //If hash matches, don't do anything
      var old = vm_cache[ns][page._id];
      if (old && old._hash == page._hash) { return; }

      //Changes were integrated
      if (cl_id) {
        //We have to have a cached version
        if (!old) { raise "Tried to integrate changes with id: " + cl_id + " but there was no cached page that could have had a changelist"};

        //The cached version should have a change list
        if (!old._chead) { raise "Tried to integrate changes with id: " + cl_id + " but there was no changelist present" };

        var chead = old._chead;
        var ctail = old._ctail;

        //Ensure Ids match
        var old_cl_id = chead._id;
        if (cl_id != old_cl_id) {
          raise "Integrating changes, but the head changelist id was " + old_cl_id + "while the attempted integration was " + cl_id;
        }

        //Increment head
        old._chead = old._chead._next;

        //If head is now null, the tail no longer exists
        if (!chead) {
          ctail = null;
        }
      }

      //Set pages change list pointers
      page._chead = old._chead;
      page._ctail = old._ctail;

      //Now replay the diff

      //We're ok to write the page
      vm_cache_write(ns, page);
    }
    */

    //Cache
    function vm_cache_write(ns, page) {
      //If hash matches, don't write
      var old = vm_cache[ns][page._id];
      if (old && old._hash == page._hash) { return; }

      vm_dirty[ns][page._id] = page;
      vm_cache[ns][page._id] = page;

      //Try to lookup listeners to notify
      var nbp = vm_notify_map[ns][page._id];
      if (nbp) {
        for (var i = 0; i < nbp.length; ++i) {
          var bp = nbp[i];

          //If the receiver requested a diff mode in watch...
          if (vm_diff_bps[bp]) {
            var diff = vm_diff(old, page);

            //Still send read_res
            if (vm_transaction_in_progress) {
              vm_transaction_queue.push([bp, "read_res_update", page]);
            } else {
              int_event_defer(bp, "read_res_update", page);
            }

            while (diff.length > 0) {
              var e = diff.pop();
              var _type = e[0];
              if (_type === "modify") {
                if (vm_transaction_in_progress) {
                  vm_transaction_queue.push([bp, "entry_modified", {page_id: page._id, entry: e[1]}]);
                } else {
                  int_event_defer(bp, "entry_modified", {page_id: page._id, entry: e[1]});
                }
              } else if (_type === "insert") {
                if (vm_transaction_in_progress) {
                  var delete_map_info = vm_transaction_delete_map[e[1]._id];
                  if (delete_map_info) {
                    var was_deleted_index = delete_map_info[1];
                  }
                  //Checking if it was deleted in another page, this means it was moved...
                  if (delete_map_info) {
                    //Remove deletion from the transaction queue
                    vm_transaction_queue.splice(was_deleted_index, 1);

                    //Insert a move *to* this page
                    vm_transaction_queue.push([bp, "entry_moved", {from_page: delete_map_info[0], to_page: page._id, entry: e[1]}]);
                  } else {
                    vm_transaction_queue.push([bp, "entry_inserted", {page_id: page._id, entry: e[1]}]);
                    vm_transaction_insert_map[e[1]] = vm_transaction_queue.length-1;
                  }
                } else {
                  int_event_defer(bp, "entry_inserted", {page_id: page._id, entry: e[1]});
                }
              } else if (_type === "delete") {
                if (vm_transaction_in_progress) {
                  vm_transaction_queue.push([bp, "entry_deleted", {page_id: page._id, entry_id: e[1]}]);
                  vm_transaction_delete_map[e[1]] = [page._id, vm_transaction_queue.length-1];
                } else {
                  int_event_defer(bp, "entry_deleted", {page_id: page._id, entry_id: e[1]});
                }
              }
            }
          } else {
            int_event_defer(bp, "read_res", page);
          }
        }
      }
    }

    //Transactions are meant for cache writes, multiple pages can be written in a transaction
    //Which can allow things like differential watching to detect moves across page boundaries.
    function vm_transaction_begin() {
      vm_transaction_in_progress = true;
      vm_transaction_queue = [];
      vm_transaction_insert_map = {};
      vm_transaction_delete_map = {};
    }

    function vm_transaction_end() {
      vm_transaction_in_progress = false;

      for (var i = 0; i < vm_transaction_queue.length; ++i) {
        var e = vm_transaction_queue[i];
        int_event_defer(e[0], e[1], e[2]);
      }
    }

    function vm_page_replay(page, diff) {
      for (var i = 0; i < diff.length; ++i) {
        var e = diff[i];
        var type = e[0];

        //Insert it at the beginning
        if (type === "insert") {
          page.entries.splice(0, 1, e[1]);
        } else if (type === "modify") {
          var idx = -1;
          for (var i = 0; i < page.entries.length; ++i) {
            if (page.entries[i]._id == e[1]._id) { idx = i; break; };
          }

          if (idx === -1) { throw "Couldn't find element with matching id" };
          page.entries[idx] = e[1];
        }
      }
    }

    function vm_diff(old_page, new_page) {
      //All diff messages end up here
      var diff_log = [];

      var entry_diff = {};
      //Old entrys first
      for (var i = 0; i < old_page.entries.length; ++i) {
        var old_entry = old_page.entries[i];
        var _id = old_entry._id;
        var _sig = old_entry._sig;

        entry_diff[_id] = _sig;
      }

      //New entrys
      for (var i = 0; i < new_page.entries.length; ++i) {
        var new_entry = new_page.entries[i];
        var _id = new_entry._id;
        var _sig = new_entry._sig;

        //Modify:
        //  Existed in old entry and the signature is different
        var old_sig = entry_diff[_id];
        if (old_sig) {
          if (old_sig != _sig) {
            diff_log.push(["modify", new_entry]);
          }

          delete entry_diff[_id];
        }

        //Inserted, old_sig didn't exist
        else {
          diff_log.push(["insert", new_entry]);
        }
      }

      //Remaining have been deleted
      var old_ids = Object.keys(entry_diff);
      while (old_ids.length > 0) {
          diff_log.push(["delete", old_ids.pop()]);
      }

      return diff_log;
    }

    function vm_rehash_page(page) {
      var z = 0;

      //head and next are optional
      if (page._head) { var z = crc32(0, page._head) }
      if (page._next) { z = crc32(z, page._next) }

      z = crc32(z, page._id)

      //Hash differently based on type
      if (page._type === "array") {
        var e = page.entries;
        for (var i = 0; i < e.length; ++i) {
          z = crc32(z, e[i]._sig);
        }
      } else if (page._type === "hash") {
        var keys = Object.keys(page.entries);
        var e = page.entries;
        var q = 0;
        for (var i = 0; i < keys.length; ++i) {
          var _sig = e[keys[i]]._sig;
          var r = crc32(0, _sig);
          q = q + r;
        }
        q = +q;
        z = crc32(z, q.toString());
      } <% if @debug %> else {
        throw "vm_rehash_page got an unspported type: "+page._type;
      }
      <% end %>
      page._hash = z.toString();
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
    function int_per_get_res(s, ns, res) {
      //If the key didn't exist, ignore it
      if (res === null) { return; }

      //If there is already a cached entry, a pager beat us to it
      //ignore this for now because the pager should be more up to
      //date
      if (vm_cache[ns][res._id]) { return };

      vm_cache_write(ns, res);
    }

    <% if @debug %>
      vm_write_list = [];
    <% end %>
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
        var arr = nn[nnk[i]][0]
        var idx = nn[nnk[i]][1]

        //Remove
        arr.splice(idx, 1);
      }

    }

    //Now we just clean up vm_bp_to_nmap because it's no longer used
    delete vm_bp_to_nmap[bp];
  }

  on "write", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    //We are going to fix the _hash on the page
    vm_rehash_page(params.page);

    <% if @debug %>
      vm_write_list.push(params.page);
    <% end %>

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_write(params.page);
      }
    <% end %>
  }

  on "watch", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    //Cache entry
    var cache_entry = vm_cache[params.ns][params.id];

    //Diff?
    if (params.diff === true) {
      vm_diff_bps[bp] = true;
    }

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
    if (!cache_entry && params.sync) {
      SEND("main", "if_per_get", "vm", params.ns, params.id);
    }

    //Do not signal pager if there is a watch request already in place
    //as pager already knows; if it's equal to 1, this is the 'first'
    //watch to go through as we have no info on it but just added it
    if (vm_notify_map[params.ns][params.id].length > 1) { return; }

    //While we're waiting for the pager try loading from disk, if this
    //disk request is slower than the pager response, that's ok...
    //the disk response will double check to see if the cache got set
    //somewhere and not set it itself.
    if (!cache_entry && !params.sync) {
      SEND("disk", "if_per_get", "vm", params.ns, params.id);
    }

    //Now load the appropriate pager
    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_watch(params.id, cache_entry);
      }
    <% end %>
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

    delete vm_bp_to_nmap[bp][params.ns][params.id];
    delete vm_diff_bps[bp];

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_unwatch(params.id);
      }
    <% end %>
  }

  every 20.seconds, %{
    vm_pageout();
  }
end
