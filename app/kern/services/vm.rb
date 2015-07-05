service :vm do
  global %{
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

    //Notification listeners, converts ns+key to an array of base pointers
    vm_notify_map = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //Cache
    function vm_cache_write(ns, page) {
      var old = vm_cache[ns][page._id];
      if (old && old._hash == page._hash) { return; }

      vm_dirty[ns][page._id] = page;
      vm_cache[ns][page._id] = page;

      //Try to lookup view controller(s) to notify
      var nbp = vm_notify_map[ns][page._id];
      if (nbp) {
        for (var i = 0; i < nbp.length; ++i) {
          int_event_defer(nbp[i], "read_res", page);
        }
      }
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
    ///////////////////////////////////////////////////////////////////////////

    //vm_diff helpers
    ///////////////////////////////////////////////////////////////////////////
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
            diff_log.push(["M", i, new_entry]);
          }
          delete entry_diff[_id];
        }
        //Inserted, old_sig didn't exist
        else {
          diff_log.push(["+", i, new_entry]);
        }
      }

      //Remaining have been deleted
      var old_ids = Object.keys(entry_diff);
      while (old_ids.length > 0) {
          diff_log.push(["-", old_ids.pop()]);
      }

      return diff_log;
    }

    function vm_diff_replay(page, diff) {
      for (var i = 0; i < diff.length; ++i) {
        var e = diff[i];

        //vm_diff type
        var type = e[0];
        if (type === "+") {
          var eindex = e[1];
          var entry = e[2];

          //Insertion
          page.entries.splice(eindex, 0, entry);
        } else if (type === "M") {
          var eindex = e[1];
          var entry = e[2];

          //Take out old, put in new
          page.entries.splice(eindex, 1, entry);
        }
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
