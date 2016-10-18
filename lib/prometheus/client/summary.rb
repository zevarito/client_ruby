# encoding: UTF-8

require 'quantile'
require 'prometheus/client/metric'

module Prometheus
  module Client
    # Summary is an accumulator for samples. It captures Numeric data and
    # provides an efficient quantile calculation mechanism.
    class Summary < Metric
      extend Gem::Deprecate

      # Value represents the state of a Summary at a given point.
      class Value < Hash
        attr_accessor :sum, :total

        def initialize(estimator)
          @sum = estimator.sum
          @total = estimator.observations

          estimator.invariants.each do |invariant|
            self[invariant.quantile] = estimator.query(invariant.quantile)
          end
        end
      end

      def type
        :summary
      end

      # Records a given value.
      def observe(labels, value)
        label_set = label_set_for(labels)
        @store[label_set].observe(value)
      end
      alias add observe
      deprecate :add, :observe, 2016, 10

      # Returns the value for the given label set
      def get(labels = {})
        @validator.valid?(labels)

        Value.new(@store[labels])
      end

      def values
        @store.values do |value|
          Value.new(value)
        end
      end

      def default
        Quantile::Estimator.new
      end
    end
  end
end
