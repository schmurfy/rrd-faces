
function showGraph(container, url, attrs){
  var attrs = attrs || {};
  
  $(document).ready(function() {
      $.getJSON(url, attrs, function(data){
          var opts = data['options'];
          opts['legend'] = opts['legend'] || {};
          opts['legend']['container'] = $(container).parent().find('.legend');
          $.plot($(container), data['data'], opts);
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


