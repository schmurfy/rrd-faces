module RRDFaces
  module GraphSeries
    class LineGraphSerie < Base
      attr_accessor :lineWidth
    
      def type
        'lines'
      end
    end
  end
end
