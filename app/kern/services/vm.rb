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

    //Cache
    function vm_cache_write(ns, page) {
      vm_cache[ns][page._id] = page;
    }

    //Notification of a change
    function vm_notify(ns, key) {
      var a = vm_notify_map[ns];
      if (a) {
        var b = a[key];

        if (b) {
          for (var i = 0; i < b.length; ++i) {
            <% @options[:pagers].each do |p| %>
              if (ns === "<%= p[:namespace] %>") {
                <%= p[:name] %>_read(ns, b[i], key);
              }
            <% end %>
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

  on "read", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    var cres = vm_cache[params.ns][params.key]; 
    if (cres != undefined) {
      int_event(bp, "read_res", {key: params.key, value: cres});
    }

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_read(params.ns, bp, params.key);
      }
    <% end %>
  }

  on "write", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_write(params.key, params.value);
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

    var b = a[params.key];
    if (!b) {
      b = [];
      a[params.key] = b;
    }

    b.push(bp)
    ////////////////////////////////////////////////

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_watch(params.id, cache_entry);
      }
    <% end %>
  }

  on "unwatch", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_unwatch(params.ns, params.key);
      }
    <% end %>
  }

end
