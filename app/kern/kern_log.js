<% if @debug %>
kern_log_stdout = [];
function kern_log(str) {
  kern_log_stdout.push(str);
}

function kern_log_json(json) {
  //We don't want to capture a reference
  kern_log_stdout.push(
      JSON.parse(JSON.stringify(json))
  );
}

<% end %>
