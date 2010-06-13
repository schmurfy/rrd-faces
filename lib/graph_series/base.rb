module RRDFaces
  module GraphSeries
    class Base
      @@global_properties = [:'@color', :'@label', :'@yaxis']
      @@ignored_properties = [:'@rrd_path', :'@ds_name']
      attr_accessor :color, :label, :rrd_path, :ds_name, :yaxis
    
      def initialize(attributes)
        @yaxis = 1
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

        rrd = Errand.new(:filename => File.join(RRDFaces::rrd_base_folder, machine, self.rrd_path))
        rrd_data = rrd.fetch(:function => 'AVERAGE', :start => from, :end => to)
        
        if rrd_data[:data].has_key?(ds_name)
          points = rrd_data[:data][ds_name]
          
          increment = (js_end - js_start) / points.size
          global_properties[:data] = points[0...-1].map.with_index do |y, n|
            t = js_start + increment*n
            [t, y]
          end
        
        else
          raise "DS: #{ds_name} not found in #{self.rrd_path}"
        end
        
        {"#{type}" => graph_properties}.merge(global_properties)
      end
    
    end
  end
end

