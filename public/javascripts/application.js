
var previousPoint = null;

function tooltip(event, pos, item, formatter) {
      if (item) {
          if( !previousPoint || (
                (previousPoint[0] != item.datapoint[0]) && (previousPoint[1] != item.datapoint[1])
            )){
              previousPoint = item.datapoint;

              $("#tooltip").remove();
              var y = item.datapoint[1];

              showTooltip(item.pageX, item.pageY, formatter(y));
          }
      }
      else {
          $("#tooltip").remove();
          previousPoint = null;            
      }
}



function typeSpecificOptions(data, opts, container){
  
  // find max y
  var tmp, ydata = [];
  for(var i= 0; i< data['data'].length; i++ ){
    tmp = $.map(data['data'][i]['data'], function(o){ return o.y; });
    ydata.push( Math.max.apply(Math, tmp) );
  }
  
  var max_y = Math.max.apply(Math, ydata);
  
  // TODO: compute x ticks on rounded values
  
  switch(data['type']){
    case 'speed':
      container.bind("plothover", function (event, pos, item) { tooltip(event, pos, item, format_speed); });
      opts['yaxis'] = {
          ticks : 5,
          tickFormatter : function(v, axis){ console.log(axis); return format_speed( find_nearest_speed(v)); }
        }
      break;
    
    case 'size':
      container.bind("plothover", function (event, pos, item) { tooltip(event, pos, item, format_size); });
      opts['yaxis'] = {
          ticks : 5,
          tickFormatter : function(v, axis){ console.log(axis); return format_size( find_nearest_size(v) ); }
        }
      break;
  }
  
  return opts;
}


function showTooltip(x, y, contents) {
    $('<div id="tooltip">' + contents + '</div>').css( {
        position: 'absolute',
        display: 'none',
        top: y - 5,
        left: x + 15,
        border: '1px solid #fdd',
        padding: '2px',
        'background-color': '#fee',
        opacity: 0.80
    }).appendTo("body").fadeIn(200);
}

// helper for returning the weekends in a period
function weekendAreas(axes) {
    var markings = [];
    var d = new Date(axes.xaxis.min);
    // go to the first Saturday
    d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 1) % 7))
    d.setUTCSeconds(0);
    d.setUTCMinutes(0);
    d.setUTCHours(0);
    var i = d.getTime();
    do {
        // when we don't set yaxis, the rectangle automatically
        // extends to infinity upwards and downwards
        markings.push({ xaxis: { from: i, to: i + 2 * 24 * 60 * 60 * 1000 } });
        i += 7 * 24 * 60 * 60 * 1000;
    } while (i < axes.xaxis.max);

    return markings;
}


function showGraph(container, url, attrs){
  var attrs = attrs || {};
  
  $(document).ready(function() {
      $.getJSON(url, attrs, function(data){
          var opts = data['options'];
          opts['legend'] = opts['legend'] || {};
          opts['legend']['container'] = $(container).parent().find('.legend');
          
          opts['xaxis'] = { mode: 'time' };
          opts['selection'] = {
              mode: "xy",
              color: '#CCB799'
            };
          
          opts['grid'] = {
              hoverable : true,
              hoverFill: '#ff0000',
              hoverRadius: 5,
              markings: weekendAreas,
              markingsColor: '#F1E3C6'
            };
          
          opts = typeSpecificOptions(data, opts, $(container));
          
          $.plot($(container), data['data'], opts);
          
          $(container).bind("plotselected", function (event, ranges) {
              // do the zooming
              plot = $.plot($(container), data['data'],
                            $.extend(true, {}, opts, {
                                xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to },
                                yaxis: { min: ranges.yaxis.from, max: ranges.yaxis.to }
                            }));
          });
        });
    });
}



$(document).ready(function(){
  $('.graph').each(function(n, el){
      var interval = $(el).find('select').val();
      showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {interval: interval});
    });
  
  $('.graph select').change(function(){
    // when selected option change
    var el = $(this).closest('.graph');
    var interval = $(el).find('select').val();
    showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {interval: interval});
  });
  
  $('.graph .live_update').click(function(){
    if( $(this).val() ){
      var s = $(this).closest('.graph').find('select');
      
      setInterval(
          function(){ s.trigger('change'); },
          10000
        );
    }
  });
});


