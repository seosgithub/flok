<% if @debug %>
kern_log_stdout = "";
function kern_log(str) {
  kern_log_stdout += (str + "\n")
}
<% end %>
