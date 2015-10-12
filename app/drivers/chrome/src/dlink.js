
//When the page first loads, send the current URL
function dlink_init() {
  //Get parameters
  var params = {};
  var parts = <%= @spec ? "dlink_spec_window" : "window" %>.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
    params[key] = value;
  });

  //Get URL portion
  var url = <%= @spec ? "dlink_spec_window" : "window" %>.location.protocol + '//' + <%= @spec ? "dlink_spec_window" : "window" %>.location.host + <%= @spec ? "dlink_spec_window" : "window" %>.location.pathname;

  //Reset our URL to blank (this dosen't work inside phantomJS)
<% if not @spec %>
  window.history.replaceState({}, "", "/");
<% end %>

  //Notify dlink
  int_dispatch([2, "int_dlink_notify", url, params]);
}

//The window.location struct does not work in phantomJS so we mock it during debugs
<% if @spec %>
  dlink_spec_window = {
    location: {
      protocol: "http:",
      host: "test.com:80",
      pathname: "/test",
      href: "http://test.com:80/test?foo=bar"
    }
  };
<% end %>
