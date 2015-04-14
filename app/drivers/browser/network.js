drivers = window.drivers || {}
drivers.network = {}

$(document).ready(function() {
  //drivers.network.request("GET", "http://test.services.fittr.com/ping", {}, null);
})

//A basic get request that supports callbacks
drivers.network.request = function(verb, url, params, completion) {
  $.ajax({
    url: url,
    type: verb,
    data: params,
    success: function(data) {
      data = JSON.parse(data);
      completion = completion || function() {}
      if (completion != null) {
        completion(data);
      }
    },
    error: function(xhr, status, err) {
    }
  })
}
