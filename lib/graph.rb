module RRDFaces
  class Graph
    attr_reader :label, :short_name, :axis_type
    
    include GraphSeries
    
    @@encoder = Yajl::Encoder.new
    
    def initialize(short_name, description, axis_type, options = {})
      @global_options = options
      @label = description
      @short_name = short_name
      @axis_type = axis_type
      @series = []
    end
  
    def draw_line(rrd_path, ds_name, options = {})
      options.merge!({:rrd_path => rrd_path, :ds_name => ds_name})
      serie = LineGraphSerie.new(options)
      @series << serie
      serie
    end
    
    def draw_bar(rrd_path, ds_name, options = {})
      options.merge!({:rrd_path => rrd_path, :ds_name => ds_name})
      serie = BarGraphSerie.new(options)
      @series << serie
      serie
    end
  
    def to_js
      @@encoder.encode(self.to_hash)
    end
    
    def to_hash(machine, interval, index = 0)
      # compute from, to
      to = Time.new.to_i - (index * interval)
      from = to - interval
       
      {
        :data => @series.map{|s| s.to_hash(machine, from, to) },
        :options => @global_options,
        :type => @axis_type
      }
    end
  
  end
end
