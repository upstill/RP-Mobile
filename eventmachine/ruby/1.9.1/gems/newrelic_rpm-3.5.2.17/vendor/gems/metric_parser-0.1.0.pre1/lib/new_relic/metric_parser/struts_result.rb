require 'new_relic/metric_parser/java_parser'
module NewRelic
  module MetricParser
    class StrutsResult < NewRelic::MetricParser::MetricParser
      include JavaParser

      def method_name
        "execute"
      end

      def full_class_name
        segment_1
      end

      def call_rate_suffix
        'cpm'
      end
    end
  end
end
