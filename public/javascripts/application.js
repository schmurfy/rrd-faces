
var previousPoint = null;

function pad(num){
  if( num < 10 ){
    return '0' + num;
  }
  else {
    return num;
  }
}

function tooltip(event, pos, item, formatter) {
      if (item) {
          if( !previousPoint || (
                (previousPoint[0] != item.datapoint[0]) && (previousPoint[1] != item.datapoint[1])
            )){
              previousPoint = item.datapoint;

              $("#tooltip").remove();
              var y = item.datapoint[1];
              var item_date = new Date(item.datapoint[0]);
              var date_str = pad(item_date.getHours()) + ":" + pad(item_date.getMinutes());
              showTooltip(item.pageX, item.pageY, formatter(y) + '<br/>' + date_str);
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
  
  switch(data['type']){
    case 'speed':
      container.bind("plothover", function (event, pos, item) { tooltip(event, pos, item, format_speed); });
      opts['yaxis'] = opts['y2axis'] = {
          ticks : 5,
          tickFormatter : function(v, axis){ console.log(axis); return format_speed( find_nearest_speed(v)); }
        }
      break;
    
    case 'size':
      container.bind("plothover", function (event, pos, item) { tooltip(event, pos, item, format_size); });
      opts['yaxis'] = opts['y2axis'] = {
          ticks : 5,
          tickFormatter : function(v, axis){ console.log(axis); return format_size( find_nearest_size(v) ); }
        }
      break;
    
    case 'ping':
      container.bind("plothover", function (event, pos, item) { tooltip(event, pos, item, format_ping); });
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
  
  // attrs:
  // - interval : time interval watched
  // - index : 0 = now, -1 = interval before current, ...
  
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
                                yaxis: { min: ranges.yaxis.from, max: ranges.yaxis.to },
                                y2axis: { min: ranges.y2axis.from, max: ranges.y2axis.to }
                            }));
          });
        });
    });
}



$(document).ready(function(){
  $('.graph').each(function(n, el){
      var interval = $(el).find('select').val();
      var delay = $(el).data('delay') || 0;
      
      setTimeout(function(){
        showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {
            interval: interval,
            index: 0
          });
      }, delay);
    });
  
  $('.graph select').change(function(){
    // when selected option change
    var el = $(this).closest('.graph');
    var interval = $(el).find('select').val();
    showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {interval: interval});
  });
  
  var live_update_timers = {};
  
  $('.graph .live_update').click(function(){
    var id = $(this).data('data-id');
    
    if( this.checked ){
      var s = $(this).closest('.graph').find('select');
      
      live_update_timers[id] = setInterval(
          function(){ s.trigger('change'); },
          10000
        );
    }
    else {
      clearInterval( live_update_timers[id] );
      live_update_timers[id] = null;
    }
  });
  
  $('a.reset').click(function(){
    var el = $(this).closest('.graph');
    var interval = $(el).find('select').val();
    showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {interval: interval});
  });
  
  $('a.previous').click(function(){
    var el = $(this).closest('.graph');
    var interval = $(el).find('select').val();
    var index = parseInt(el.attr('data-index')) + 1;
    el.attr('data-index', index) ;
    
    showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {interval: interval, index: index});
  });
  
  $('a.next').click(function(){
    var el = $(this).closest('.graph');
    var interval = $(el).find('select').val();
    var index = parseInt(el.attr('data-index')) - 1;
    el.attr('data-index', index) ;
    
    showGraph($(el).find('.canvas'), '/data/' + $(el).data('host') + '/' + $(el).data('name'), {interval: interval, index: index});
  });
});


