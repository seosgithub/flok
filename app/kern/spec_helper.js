<% if @debug %>
  <% if @defines['spec_test'] %>
    <% require 'pry'; binding.pry %>
    //spec_helper_defines_spec_test
  <% end %>
<% end %>
