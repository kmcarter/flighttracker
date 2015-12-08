var settings = {
  refreshInterval: 5,
  mapOptions: {
    seriesDefaults: {
      //color: '#BFFF00',
      showLine: false,
      pointLabels: {show: true, location:'se', ypadding: 5},
    },
    axes: {
      xaxes: { min: 0, max: 20000 },
      yaxes: { min: -80000, max: 60000 }
    },
    grid: {
      //gridLineColor: '#BFFF00',
      //background: '#000000', 
      //borderColor: '#BFFF00'
    }
  }
}
var refreshTimer = null;
var flightMap = null;

$(function() {
  refreshData();
  setRefreshCounter();
  $("#refresh-data").click(refreshData);
  
  $("#settings-modal").on('show.bs.modal', function(e) {
    $("#refreshInterval").val(settings.refreshInterval);
    $("#refreshIntervalValue").text(settings.refreshInterval);
  });
  $("#toggle-simulator").click(function() {
    var $button = $(this);
    $.ajax('/toggle_sim', {
      type: 'GET',
      dataType: 'json',
      success: function(data) {
        if (data.hasOwnProperty('error')) {
          alert(data.error);
        } else {
          if (data.status == 'run') {
            $button.removeClass('btn-danger').addClass('btn-success').html('<span class="glyphicon glyphicon-check" aria-hidden="true"></span> Disable Simulator');
          } else {
            $button.removeClass('btn-success').addClass('btn-danger').html('<span class="glyphicon glyphicon-unchecked" aria-hidden="true"></span> Enable Simulator');
          }
        }
      }
    });
    return false;
  });
  $("#settings-modal form").submit(function() {
    settings.refreshInterval = parseInt($("#refreshInterval").val());
    $("#settings-modal").modal('hide');
    setRefreshCounter();
    return false;
  });
  $("#new-flight-modal form").submit(function() {
    var initialSpeed = $("#new-flight-modal form input[name=speed]").val();
    $.ajax('/entry', {
      type: 'GET',
      dataType: 'json',
      data: $("#new-flight-modal form").serialize(),
      success: function(data) {
        if (data.hasOwnProperty('error')) {
          alert(data.error);
        } else {
          var msg = "Flight #" + data.flight + " has been successfully created";
          if (data.status == "diverted") {
            msg += " but has been diverted";
          } else if (data.speed != initialSpeed) {
            msg += " but its speed has been adjusted to " + data.speed;
          }
          alert(msg);
        }
      }
    });
    $("#new-flight-modal").modal('hide');
    return false;
  });
});

function refreshData() {
  $("#flight-data tbody, #arrival-data tbody").empty();
  $.ajax('/tracking_info', {
    type: 'GET',
    dataType: 'json',
    success: function(data) {
      $("#timestamp").text(new Date().toString());
      $.each(data.aircrafts, function(i, ele) {
        if (ele.status == 'landed') {
          $("<tr><td>" + ele.flight + "</td><td>" + ele.ingress + "</td><td>" + ele.time_of_arrival + "</td></tr>").appendTo("#arrival-data tbody");
        } else {
          $("<tr><td>" + ele.flight + "</td><td>" + ele.status + "</td><td>" + ele.x + "</td><td>" + ele.y + "</td><td>" + ele.speed + 
            "</td><td>" + ele.altitude + "</td><td>" + ele.ingress + "</td></tr>").appendTo("#flight-data tbody");
        }
      });
      
      if (flightMap != null) {
        flightMap.destroy();
        flightMap.series[0].data = transformMapData(data.aircrafts);
      }
      flightMap = $.jqplot('flight-map', transformMapData(data.aircrafts), settings.mapOptions);
    }
  });
  return false;
}

function setRefreshCounter() {
  if (refreshTimer != null) {
    window.clearTimeout(refreshTimer);
  }
  refreshTimer = window.setInterval(refreshData, settings.refreshInterval * 1000);
}

function transformMapData(data) {
  var mapData = [[]];
  $.each(data, function(i, ele) {
    if(ele.status != 'landed') {
      mapData[0].push([ele.x, ele.y, ele.flight]);
    }
  });
  return mapData;
}