$(function() {
  $.ajax('/tracking_info', {
    type: 'GET',
    dataType: 'json',
    success: function(data) {
      $("#data").text(data);
    }
  });
});