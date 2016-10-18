# encoding: UTF-8

require 'prometheus/client/store'

module Prometheus
  module Client
    module Stores
      # Hash
      class Hash < Store
        def initialize(metric)
          @mutex = Mutex.new
          @metric = metric
          @values = ::Hash.new { |hash, key| hash[key] = @metric.default }
        end

        def synchronize(&block)
          @mutex.synchronize(&block)
        end

        def values
          synchronize do
            @values.each_with_object({}) do |(labels, value), memo|
              memo[labels] = block_given? ? yield(value) : value
            end
          end
        end
      end
    end
  end
end
