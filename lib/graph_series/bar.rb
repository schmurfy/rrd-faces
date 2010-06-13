module RRDFaces
  module GraphSeries
    class BarGraphSerie < Base
      attr_accessor :barWidth, :fillOpacity, :borderOpacity
      
      def type
        'bars'
      end
    end
  end
end
