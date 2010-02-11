module GraphDrawer
  @@rrd_base_folder = '.'
  
  def self.rrd_base_folder=(v)
    @@rrd_base_folder = v
  end
  
  def self.rrd_base_folder
    @@rrd_base_folder
  end
  
  # graph types
  KB_VALUE = {
      :xaxis => { :mode => "time" },
      :yaxis => { :ticks => [[0, "0"]] +
          (100..900).step(100).map{|s| [s*1024**2, "#{s}&nbsp;Mo"] } +
          (1..100).map{|s| [s*1024**3, "#{s}&nbsp;Go"]}
        }
    }
  
  DISK_ACCESS = {
      :legend => {:margin => -10},
      :xaxis => { :mode => 'time'},
      :yaxis => { :ticks => [[0, "0"]] + 
          (1..10).map{|s| [s*1025*1024, "#{s} Mo/s"] }
        }
    }
  
  KB_SPEED = {
      :xaxis => { :mode => 'time'},
      :yaxis => { :ticks => [[0, "0"]] + 
          (1..9).map{|s| [s*1024, "#{s} Ko/s"] } +
          (10..100).step(10).map{|s| [s*1024, "#{s} Ko/s"] } +
          (1..10).map{|s| [s*1025*1024, "#{s} Mo/s"] }
        }
    }
  
  class Graph
    attr_reader :label, :short_name
    
    @@encoder = Yajl::Encoder.new
    
    def initialize(short_name, description, options = {})
      @global_options = options
      @label = description
      @short_name = short_name
      @series = []
    end
  
    def draw_line(rrd_path, ds_name, options = {})
      options.merge!({:rrd_path => rrd_path, :ds_name => ds_name})
      @series << LineGraphSerie.new(options)
    end
  
    def to_js
      @@encoder.encode(self.to_hash)
    end
    
    def to_hash(machine, interval = nil)
      from ||= (Time.now - (interval || 3600)).to_i
      to   ||= (Time.now).to_i
       
      {
        :data => @series.map{|s| s.to_hash(machine, from, to) },
        :options => @global_options
      }
    end

  private
    class GraphSerie
      @@global_properties = [:'@color', :'@label']
      @@ignored_properties = [:'@rrd_path', :'@ds_name']
      attr_accessor :color, :label, :rrd_path, :ds_name
    
      def initialize(attributes)
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

        rrd = Errand.new(:filename => File.join(GraphDrawer::rrd_base_folder, machine, self.rrd_path))
        rrd_data = rrd.fetch(:function => 'AVERAGE', :start => from, :end => to)
        
        if rrd_data[:data].has_key?(ds_name)
          points = rrd_data[:data][ds_name]
          
          increment = (js_end - js_start) / points.size
          global_properties[:data] = points.map.with_index{|y, n| [js_start + increment*n, y] }
        
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


    class BarsGraphSerie < GraphSerie
      def type
        'bars'
      end
    end
  
  end


  def self.define_graph(short_name, description, opts = {})
    raise "block required" unless block_given?
  
    g = Graph.new(short_name, description, opts)
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



