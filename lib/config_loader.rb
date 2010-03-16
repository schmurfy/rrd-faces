module GraphDrawer
  @@rrd_base_folder = '.'
  
  def self.rrd_base_folder=(v)
    @@rrd_base_folder = v
  end
  
  def self.rrd_base_folder
    @@rrd_base_folder
  end
  
  class Graph
    attr_reader :label, :short_name, :axis_type
    
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
      serie = LineGraphSerie.new(options, options.delete(:base))
      @series << serie
      serie
    end
    
    def draw_bar(rrd_path, ds_name, options = {})
      options.merge!({:rrd_path => rrd_path, :ds_name => ds_name})
      serie = BarGraphSerie.new(options, options.delete(:base))
      @series << serie
      serie
    end
  
    def to_js
      @@encoder.encode(self.to_hash)
    end
    
    def to_hash(machine, interval = nil)
      from ||= (Time.now - (interval || 3600)).to_i
      to   ||= (Time.now).to_i
       
      {
        :data => @series.map{|s| s.to_hash(machine, from, to) },
        :options => @global_options,
        :type => @axis_type
      }
    end

  private
    class GraphSerie
      @@global_properties = [:'@color', :'@label']
      @@ignored_properties = [:'@rrd_path', :'@ds_name']
      attr_accessor :color, :label, :rrd_path, :ds_name
    
      def initialize(attributes, base = nil)
        @base = base
        _load_data(attributes)
      end
    
      def _load_data(attributes)
        unknown = attributes.reject do |key, value|
          if respond_to?("#{key}=")
            send("#{key}=", value)
            true
          else
            false
          end
        end
      
        unless unknown.empty?
          fail "unknown parameter(s) in config block #{self.class}: #{unknown.inspect}"
        end
      end
    
      def to_hash(machine, from = nil, to = nil)
      
        graph_properties = {"show" => true}
        (instance_variables - (@@ignored_properties + @@global_properties)).each do |property_name|
          js_property_name = (property_name[0] == '@') ? property_name[1..-1] : property_name
          graph_properties[js_property_name] = instance_variable_get(property_name)
        end
      
        global_properties = {}
        @@global_properties.each do |property_name|
          js_property_name = (property_name[0] == '@') ? property_name[1..-1] : property_name
          global_properties[js_property_name] = instance_variable_get(property_name)
        end
        
        # add data
        from ||= (Time.now - 3600).to_i
        to   ||= (Time.now).to_i

        js_start = 1000 * from
        js_end = 1000 * to

        data = []
        
        # load base data if any given
        if @base
          rrd_base = Errand.new(:filename => File.join(GraphDrawer::rrd_base_folder, machine, @base[0]))
          rrd_base_data = rrd_base.fetch(:function => 'AVERAGE', :start => from, :end => to)[:data][@base[1]]
        else
          rrd_base_data = proc{ nil }
        end

        rrd = Errand.new(:filename => File.join(GraphDrawer::rrd_base_folder, machine, self.rrd_path))
        rrd_data = rrd.fetch(:function => 'AVERAGE', :start => from, :end => to)
        
        if rrd_data[:data].has_key?(ds_name)
          points = rrd_data[:data][ds_name]
          
          increment = (js_end - js_start) / points.size
          global_properties[:data] = points.map.with_index do |y, n|
            { :x => js_start + increment*n, :y => y, :base => rrd_base_data[n] }
          end
        
        else
          raise "DS: #{ds_name} not found in #{self.rrd_path}"
        end
        
        {"#{type}" => graph_properties}.merge(global_properties)
      end
    
    end


    class LineGraphSerie < GraphSerie
      attr_accessor :lineWidth
    
      def type
        'lines'
      end
    end


    class BarGraphSerie < GraphSerie
      attr_accessor :barWidth, :fillOpacity, :borderOpacity
      
      def type
        'bars'
      end
    end
  
  end


  def self.define_graph(short_name, description, type = :default, opts = {})
    raise "block required" unless block_given?
  
    g = Graph.new(short_name, description, type, opts)
    yield(g)
    g
  end
  
  
  @view = nil
  
  def self.view
    @view
  end
  
  def self.define_views
    raise "block required" unless block_given?

    inner_class = Class.new do
      attr_reader :default, :machines

      def initialize
        @machines = {}
        @default = {}
      end

      def set_default(*list)
        list.each do |g|
          @default[g.short_name.to_sym] = g
        end
      end

      def add_machine(name, *list)
        list = Array(list.first) if list.size == 1
        
        @machines[name] = {}
        list.each do |g|
          @machines[name.to_sym][g.short_name.to_sym] = g
        end
      end
    end

    obj = inner_class.new
    yield(obj)
    @view = obj
  end
end



