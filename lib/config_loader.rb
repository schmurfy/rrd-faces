module RRDFaces
  @@rrd_base_folder = '.'
  
  def self.rrd_base_folder=(v)
    @@rrd_base_folder = v
  end
  
  def self.rrd_base_folder
    @@rrd_base_folder
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
          @machines[name][g.short_name.to_sym] = g
        end
      end
    end

    obj = inner_class.new
    yield(obj)
    @view = obj
  end
end



