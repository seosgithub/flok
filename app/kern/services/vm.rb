service :vm do
  on_wakeup %{
    <% if @debug %>
      vm_did_wakeup = true;
    <% end %>
  }

  on_sleep %{
  }

  on_connect %{
  }

  on_disconnect %{
  }

  every 1.seconds, %{
  }

  on "read_sync", %{
    <% raise "No pagers given in options for vm" unless @options[:pagers] %>
    <% @options[:pagers].each do |p| %>
      if (params.ns === "<%= p[:namespace] %>") {
        <%= p[:name] %>_read_sync();
      }
    <% end %>
    vm_read_sync_called = true;
  }
end
