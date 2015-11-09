# encoding: UTF-8

require 'prometheus/client/metric'

module Prometheus
  module Client
    # Counter is a metric that exposes merely a sum or tally of things.
    class Counter < Metric
      def type
        :counter
      end

      def increment(labels = {}, by = 1)
        fail ArgumentError, 'increment must be a non-negative number' if by < 0

        label_set = label_set_for(labels)
        synchronize do
          @store.transaction do
            @store[label_set] ||= default
            @store[label_set] += by
          end
        end
      end

      private

      def default
        0
      end
    end
  end
end
