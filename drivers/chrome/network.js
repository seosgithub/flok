drivers.network = {}

$(document).ready(function() {
  drivers.network.request("GET", "http://test.services.fittr.com/ping", {}, null);
})

drivers.network.request = function(verb, url, params, completion) {
  $.ajax({
    url: url,
    type: verb,
    success: function(data) {
    },
    error: function(xhr, status, err) {
    }
  })
}
