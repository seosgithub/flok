service :vm do
  global %{
    //Cache contains a blank hash for each namespace
    vm_cache = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //Notification listeners, converts ns+key to an array of base pointers
    vm_notify_map = {};

    //Namespaces and page ids that are current being watched
    vm_watched_keys = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //Cache
    function vm_cache_write(ns, page) {
      var old = vm_cache[ns][page._id];
      if (old && old._hash == page._hash) { return; }

      vm_cache[ns][page._id] = page;

      var a = vm_notify_map[ns];
      if (a) {
        var b = a[page._id];

        if (b) {
          for (var i = 0; i < b.length; ++i) {
            int_event(b, "read_res", page);
          }
        }
      }
    }

    function vm_rehash_page(page) {
      var z = 0;

      //head and next are optional
      if (page._head) { var z = crc32(0, page._head) }
      if (page._next) { z = crc32(z, page._next) }

      z = crc32(z, page._id)

      var e = page.entries;
      for (var i = 0; i < e.length; ++i) {
        z = crc32(z, e[i]._sig);
      }

      page._hash = z.toString();
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
  }

  on_disconnect %{
  }

  on "read_sync", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    var cres = vm_cache[params.ns][params.key]; 
    if (cres != undefined) {
      int_event(bp, "read_res", {key: params.key, value: cres});
      return;
    }

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        var res = <%= p[:name] %>_read_sync(params.ns, bp, params.key);
      }
    <% end %>
    vm_read_sync_called = true;

    int_event(bp, "read_sync_res", res);
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
    var a = vm_notify_map[params.ns];
    if (!a) {
      a = {};
      vm_notify_map[params.ns] = a;
    }

    var b = a[params.id];
    if (!b) {
      b = [];
      a[params.id] = b;
    }

    <% if @debug %>
      var midx = vm_notify_map[params.ns][params.id].indexOf(bp)
      if (midx != -1) {
        throw "Multiple calls to watch for the ns: " +  params.ns + " and id: " + params.id
      }
    <% end %>
    b.push(bp)
    ////////////////////////////////////////////////

    //If cache exists, then signal controller *now* while we wait for the pager
    if (cache_entry) {
      int_event(bp, "read_res", cache_entry);
    }

    //Do not signal pager if there is a watch request already in place
    //as pager already knows
    if (vm_watched_keys[params.ns][params.id] > 0) {
      vm_watched_keys[params.ns][params.id] += 1;
      return;
    }

    vm_watched_keys[params.ns][params.id] = 1;
    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_watch(params.id, cache_entry);
      }
    <% end %>
  }

  on "unwatch", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    //Decrement watched count
    vm_watched_keys[params.ns][params.id] -= 1;

    var midx = vm_notify_map[params.ns][params.id].indexOf(bp)
    vm_notify_map[params.ns][params.id].splice(midx, 1);

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_unwatch(params.id);
      }
    <% end %>
  }

end
