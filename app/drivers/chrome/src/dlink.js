
//When the page first loads, send the current URL
function dlink_init() {
  //Get parameters
  var params = {};
  var parts = <%= @debug ? "dlink_spec_window" : "window" %>.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
    params[key] = value;
  });

  //Get URL portion
  var url = <%= @debug ? "dlink_spec_window" : "window" %>.location.protocol + '//' + <%= @debug ? "dlink_spec_window" : "window" %>.location.host + <%= @debug ? "dlink_spec_window" : "window" %>.location.pathname;

  //Notify dlink
  int_dispatch([2, "int_dlink_notify", url, params]);
}

//The window.location struct does not work in phantomJS so we mock it during debugs
<% if @debug %>
  dlink_spec_window = {
    location: {
      protocol: "http:",
      host: "test.com:80",
      pathname: "/test",
      href: "http://test.com:80/test?foo=bar"
    }
  };
<% end %>

