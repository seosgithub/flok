service :vm do
  global %{
    //Cache contains a blank hash for each namespace
    vm_cache = {
      <% @options[:pagers].each do |p| %>
        <%= p[:namespace] %>: {},
      <% end %>
    };

    //Cache
    function vm_cache_write(ns, key, value) {
      vm_cache[ns][key] = value;
    }
  }

  on_wakeup %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>

    <% if @debug %>
      vm_did_wakeup = true;
    <% end %>


    //Call init functions
    <% @options[:pagers].each do |p| %>
      <%= p[:name] %>_init(<%= (p[:options] || {}).to_json %>);
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
end
