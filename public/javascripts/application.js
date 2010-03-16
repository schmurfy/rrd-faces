
function typeSpecificOptions(data, opts){
  
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
      opts['hints'] = opts['hints'] || { show : true };
      opts['hints']['hintFormatter'] = function( datapoint ){ return format_speed(datapoint['y']); }
      opts['yaxis'] = {
          ticks : 5,
          tickFormatter : function(v, axis){ console.log(axis); return format_speed( find_nearest_speed(v)); }
        }
      break;
    
    case 'size':
      opts['hints'] = opts['hints'] || { show : true };
      opts['hints']['hintFormatter'] = function( datapoint ){ return format_size(datapoint['y']); }
      opts['yaxis'] = {
          ticks : 5,
          tickFormatter : function(v, axis){ console.log(axis); return format_size( find_nearest_size(v) ); }
        }
      break;
  }
  
  return opts;
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
              mode: "x",
              color: '#CCB799'
            };
          
          opts['grid'] = {
              hoverable : true,
              hoverFill: '#ff0000',
              hoverRadius: 5
            };
          
          opts = typeSpecificOptions(data, opts);
          
          $.plot($(container), data['data'], opts);
          
          $(container).bind("plotselected", function (event, ranges) {
              // do the zooming
              plot = $.plot($(container), data['data'],
                            $.extend(true, {}, opts, {
                                xaxis: { min: ranges.x1, max: ranges.x2 }//,
                                // yaxis: { min: ranges.y1, max: ranges.y2 }
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


