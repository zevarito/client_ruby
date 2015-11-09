# encoding: UTF-8

module Prometheus
  module Client
    class Store
      def get(labels = {})
        synchronize do
          @values[labels]
        end
      end

      def [](labels = {})
        synchronize do
          val = @values[labels]
          return @metric.default unless val
          return val
        end
      end

      def []=(labels, value)
        synchronize do
          @values[labels] ||= @metric.default
          @values[labels] = value
        end
      end

      def increment(labels, value)
        synchronize do
          @values[labels] ||= @metric.default
          @values[labels] += value
        end
      end
    end
  end
end
